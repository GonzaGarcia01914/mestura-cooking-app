/* eslint-disable no-console */
// Cloud Functions v2 (JS, CommonJS)
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");

// Inicializa Admin
initializeApp();

// Secret en Secret Manager
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Opciones comunes (App Check DESACTIVADO)
const commonOpts = {
    region: "europe-west1",
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [OPENAI_API_KEY],
    cors: true,
    enforceAppCheck: false,
};

// --- Helpers OpenAI REST ---
const CHAT_URL = "https://api.openai.com/v1/chat/completions";
const MOD_URL = "https://api.openai.com/v1/moderations";
const IMG_URL = "https://api.openai.com/v1/images/generations";

// Modelos
const CHAT_MODEL = "gpt-4o-mini";
const MOD_MODEL = "omni-moderation-latest";

// Parse estricto a JSON
function strictParseJson(raw) {
    if (!raw || typeof raw !== "string") {
        throw new Error("Empty model response.");
    }
    let s = raw.trim();
    if (s.startsWith("```")) {
        s = s.replace(/^```json\s*/i, "");
        s = s.replace(/```$/i, "");
        s = s.replace(/```/g, "").trim();
    }
    const start = s.indexOf("{");
    const end = s.lastIndexOf("}");
    if (start === -1 || end === -1 || end <= start) {
        throw new Error("JSON not found in model output.");
    }
    const jsonString = s.substring(start, end + 1);
    return JSON.parse(jsonString);
}

function validStringArray(v) {
    return Array.isArray(v) && v.length > 0 && v.every((e) => typeof e === "string" && e.trim().length > 0);
}

// Moderación (true = bloqueado)
async function isFlagged(text, apiKey) {
    const r = await fetch(MOD_URL, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: MOD_MODEL,
            input: String(text ?? ""),
        }),
    });
    if (!r.ok) {
        const body = await r.text().catch(() => "");
        throw new Error(`Moderation failed: ${r.status} ${body}`);
    }
    const data = await r.json();
    const result = (data.results || [])[0] || {};
    return result.flagged === true;
}

// === Callable: isFood ===
exports.isFood = onCall(commonOpts, async (req) => {
    try {
        console.log("[isFood] hasAppCheck =", !!req.appCheckToken);

        const apiKey = OPENAI_API_KEY.value();
        const query = String(req.data?.query ?? "").trim();
        if (!query) throw new HttpsError("invalid-argument", "Missing 'query'.");

        const body = {
            model: CHAT_MODEL,
            messages: [
                {
                    role: "system",
                    content:
                        'You are a food filter. Reply with ONLY "yes" if the input is food or edible, otherwise ONLY "no".',
                },
                { role: "user", content: `Is this food? "${query}"` },
            ],
            temperature: 0.0,
            max_tokens: 2,
        };

        const r = await fetch(CHAT_URL, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(body),
        });
        if (!r.ok) {
            const t = await r.text().catch(() => "");
            throw new HttpsError("internal", `OpenAI chat failed: ${r.status} ${t}`);
        }
        const data = await r.json();
        const content = String(data?.choices?.[0]?.message?.content ?? "").trim().toLowerCase();
        return { ok: content === "yes" };
    } catch (err) {
        console.error("[isFood] error:", err);
        if (err instanceof HttpsError) throw err;
        throw new HttpsError("internal", String(err?.message || err));
    }
});

// === Callable: generateRecipe ===
exports.generateRecipe = onCall(commonOpts, async (req) => {
    try {
        console.log("[generateRecipe] hasAppCheck =", !!req.appCheckToken);

        const apiKey = OPENAI_API_KEY.value();

        const query = String(req.data?.query ?? "").trim();
        const language = String(req.data?.language ?? "es").trim();
        const restrictions = Array.isArray(req.data?.restrictions) ? req.data.restrictions : [];
        const servings = Math.max(1, Math.min(20, parseInt(req.data?.servings ?? 2, 10) || 2));
        const generateImage = Boolean(req.data?.generateImage);
        const imageSize = String(req.data?.imageSize ?? "1024x1024");

        // NUEVO: opciones de nutrición
        const includeMacros = Boolean(req.data?.includeMacros);
        const maxCaloriesKcal =
            req.data?.maxCaloriesKcal != null ? parseInt(req.data.maxCaloriesKcal, 10) : null;

        if (!query) throw new HttpsError("invalid-argument", "Missing 'query'.");
        if (!language) throw new HttpsError("invalid-argument", "Missing 'language'.");

        // Moderación del input
        if (await isFlagged(query, apiKey)) {
            throw new HttpsError("failed-precondition", "Your input was flagged as inappropriate.");
        }

        const sysLang = language.toLowerCase().startsWith("es") ? "Spanish" : "English";

        // Prompt del sistema
        const nutritionRule = includeMacros
            ? `
Also include a "nutrition" object with estimated per-serving values (numbers only, not strings):
{
  "calories_kcal": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "fiber_g": number,
  "sugar_g": number,
  "sodium_mg": number
}
`
            : `
Set "nutrition" to null.
`;

        const caloriesRule =
            includeMacros && Number.isFinite(maxCaloriesKcal)
                ? `Ensure estimated calories per serving are <= ${maxCaloriesKcal}. If needed, adjust the recipe realistically (portion sizes/ingredients) to meet this limit.`
                : "";

        const systemPrompt = `
You are a chef assistant. Return ONLY a single valid JSON object with this exact structure:
{
  "title": "string, non-empty",
  "ingredients": ["string", "..."],
  "steps": ["string", "..."],
  "image": "string URL or empty",
  "nutrition": object or null
}
Do NOT include any markdown, backticks, or explanations.
Write ALL content in ${sysLang} and only about real food.
When the user gives just ingredients, pick a real, recognizable dish that those ingredients can authentically produce.
Scale ingredient amounts and instructions for exactly ${servings} servings.
${nutritionRule}
${caloriesRule}
`.trim();

        const userPrompt =
            `Create a complete and practical recipe for: "${query}". ` +
            `Include concise ingredient amounts and clear numbered steps.` +
            (restrictions.length ? ` Avoid these ingredients: ${restrictions.join(", ")}.` : "");

        const chatBody = {
            model: CHAT_MODEL,
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: userPrompt },
            ],
            response_format: { type: "json_object" },
            temperature: 0.8,
            max_tokens: 1000,
        };

        const chatRes = await fetch(CHAT_URL, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(chatBody),
        });
        if (!chatRes.ok) {
            const t = await chatRes.text().catch(() => "");
            throw new HttpsError("internal", `OpenAI chat failed: ${chatRes.status} ${t}`);
        }
        const chatData = await chatRes.json();
        const raw = String(chatData?.choices?.[0]?.message?.content ?? "");

        // Moderación de la salida
        if (await isFlagged(raw, apiKey)) {
            throw new HttpsError("failed-precondition", "Generated content was flagged as inappropriate.");
        }

        // Parse y validación mínima
        const parsed = strictParseJson(raw);
        const title = String(parsed?.title ?? "").trim();
        const ingredients = parsed?.ingredients;
        const steps = parsed?.steps;
        let image = String(parsed?.image ?? "").trim();
        const nutrition = parsed?.nutrition ?? null; // puede ser objeto o null

        if (!title || !validStringArray(ingredients) || !validStringArray(steps)) {
            throw new HttpsError("internal", "Invalid recipe format from model.");
        }

        // Imagen opcional
        if (generateImage) {
            try {
                const foodPrompt =
                    (sysLang === "Spanish"
                        ? "Fotografía profesional realista de comida"
                        : "Realistic professional food photography") +
                    ` of a dish called "${title}". Ingredients: ${ingredients
                        .slice(0, 10)
                        .join(", ")}. Natural lighting, on a clean table, high detail, shallow depth of field.`;

                const imgRes = await fetch(IMG_URL, {
                    method: "POST",
                    headers: {
                        Authorization: `Bearer ${apiKey}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        model: "dall-e-3",
                        prompt: foodPrompt,
                        n: 1,
                        size: imageSize,
                        quality: "standard",
                    }),
                });
                if (imgRes.ok) {
                    const imgData = await imgRes.json();
                    const maybeUrl = imgData?.data?.[0]?.url;
                    if (typeof maybeUrl === "string" && /^https?:\/\//i.test(maybeUrl)) {
                        image = maybeUrl;
                    }
                } else {
                    const t = await imgRes.text().catch(() => "");
                    console.warn("[images] generation failed:", imgRes.status, t);
                }
            } catch (e) {
                console.warn("[images] error:", e);
            }
        }

        return {
            title,
            ingredients,
            steps,
            image,      // "" si no hay
            servings,   // útil para la UI
            nutrition,  // objeto o null
        };
    } catch (err) {
        console.error("[generateRecipe] error:", err);
        if (err instanceof HttpsError) throw err;
        throw new HttpsError("internal", String(err?.message || err));
    }
});
