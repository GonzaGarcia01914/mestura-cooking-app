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

const LANGUAGE_NAMES = {
    en: "English",
    es: "Spanish",
    de: "German",
    fr: "French",
    pt: "Portuguese",
    ru: "Russian",
    pl: "Polish",
    it: "Italian",
    ja: "Japanese",
    zh: "Chinese",
    ko: "Korean",
    gn: "Guarani",
};

function resolveSysLang(code) {
    const normalized = String(code || "").toLowerCase();
    for (const key of Object.keys(LANGUAGE_NAMES)) {
        if (normalized.startsWith(key)) {
            return LANGUAGE_NAMES[key];
        }
    }
    return "English";
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
            const errText = await r.text().catch(() => "");
            throw new HttpsError("internal", `OpenAI chat failed: ${r.status} ${errText}`);
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

        // New: time and skill options
        const tlmRaw = req.data?.timeLimitMinutes;
        const timeLimitMinutes = tlmRaw != null ? parseInt(tlmRaw, 10) : null;
        const skillRaw = String(req.data?.skillLevel ?? "").trim().toLowerCase();
        const skillLevel = ["basic", "standard", "elevated"].includes(skillRaw) ? skillRaw : "";

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

        const sysLang = resolveSysLang(language);
        // Translator helper must be defined BEFORE any use
        const translate = (en, es) => (sysLang === 'Spanish' ? es : en);

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

        const timeRule = Number.isFinite(timeLimitMinutes) && timeLimitMinutes > 0
            ? translate(
                `Total time (prep + cooking) must be <= ${timeLimitMinutes} minutes. Choose realistic techniques and ingredient prep to fit the limit; if the requested dish cannot fit, propose a similar authentic dish that does.`,
                `El tiempo total (preparación + cocción) debe ser <= ${timeLimitMinutes} minutos. Elige técnicas y preparación realistas para ajustarte al límite; si el plato solicitado no cabe, propone uno similar y auténtico que sí.`
              )
            : "";

        const skillRule = skillLevel === 'basic'
            ? translate(
                'Assume a beginner cook: avoid advanced techniques, keep steps simple and explicit, mention basic tips when needed.',
                'Asume un cocinero principiante: evita técnicas avanzadas, mantén pasos simples y explícitos, menciona consejos básicos cuando sea necesario.'
              )
            : skillLevel === 'elevated'
                ? translate(
                    'Assume an advanced cook: allow sophisticated techniques and finishing; be precise yet concise; keep it practical.',
                    'Asume un nivel avanzado: permite técnicas y acabados más sofisticados; sé preciso pero conciso; mantén la receta práctica.'
                  )
                : ""; // standard or not set

        // Preferences handling
        const prefs = req.data?.preferences || {};
        const asArray = (v) => (Array.isArray(v) ? v : []);
        const pref = {
            diet: asArray(prefs.diet),
            religion: asArray(prefs.religion),
            medical: asArray(prefs.medical),
            allergens: asArray(prefs.allergens_avoid),
            intolerances: asArray(prefs.intolerances),
            disliked: asArray(prefs.disliked_ingredients),
        };

        const t = translate; // alias for backward compatibility
        function describePrefs() {
            const lines = [];
            if (pref.diet.length) {
                lines.push(t(
                    `Follow these dietary patterns strictly: ${pref.diet.join(', ')}.`,
                    `Sigue estrictamente estos patrones de dieta: ${pref.diet.join(', ')}.`
                ));
            }
            // Strong constraints by patterns
            if (pref.diet.includes('vegan')) {
                lines.push(t(
                    'ABSOLUTELY NO animal products: no meat, fish, seafood, dairy, eggs, honey, gelatin or animal-derived additives (e.g., rennet/carmine). Use only plant-based alternatives.',
                    'PROHIBIDO TODO producto animal: sin carne, pescado, marisco, lácteos, huevos, miel, gelatina ni aditivos de origen animal (cuajo/carmín). Usa solo alternativas vegetales.'
                ));
            }
            if (pref.diet.includes('vegetarian')) {
                lines.push(t(
                    'Vegetarian: no meat, no fish or seafood. Dairy and/or eggs allowed unless otherwise specified.',
                    'Vegetariano: sin carne ni pescado/marisco. Se permiten lácteos y/o huevos salvo que se indique lo contrario.'
                ));
            }
            if (pref.diet.includes('vegetarian_ovo')) {
                lines.push(t(
                    'Ovo-vegetarian: allow eggs; no meat or fish; avoid dairy.',
                    'Ovo-vegetariano: permite huevos; sin carne ni pescado; evita lácteos.'
                ));
            }
            if (pref.diet.includes('vegetarian_lacto')) {
                lines.push(t(
                    'Lacto-vegetarian: allow dairy; no meat or fish; avoid eggs.',
                    'Lacto-vegetariano: permite lácteos; sin carne ni pescado; evita huevos.'
                ));
            }
            if (pref.diet.includes('vegetarian_strict')) {
                lines.push(t(
                    'Strict vegetarian (no egg/dairy): same restrictions as vegan.',
                    'Vegetariano estricto (sin huevo/lácteos): mismas restricciones que vegano.'
                ));
            }
            if (pref.diet.includes('pescetarian')) {
                lines.push(t(
                    'Pescetarian: fish/seafood allowed; avoid meat from land animals.',
                    'Pescetariano: permite pescado/marisco; evita carnes de animales terrestres.'
                ));
            }
            if (pref.religion.length) {
                lines.push(t(
                    `Respect these religious/cultural restrictions: ${pref.religion.join(', ')}.`,
                    `Respeta estas restricciones religiosas/culturales: ${pref.religion.join(', ')}.`
                ));
            }
            if (pref.religion.includes('halal')) {
                lines.push(t('No pork or alcohol; use halal meat if meat is used.', 'Sin cerdo ni alcohol; usa carne halal si se usa carne.'));
            }
            if (pref.religion.includes('kosher')) {
                lines.push(t('No pork or shellfish; do not mix meat and dairy in the same recipe.', 'Sin cerdo ni marisco; no mezclar carne y lácteos en la misma receta.'));
            }
            if (pref.medical.length) {
                lines.push(t(
                    `Ensure compliance with these medical/dietary restrictions: ${pref.medical.join(', ')}.`,
                    `Cumple estas restricciones médicas/dietéticas: ${pref.medical.join(', ')}.`
                ));
            }
            const avoid = [...pref.allergens, ...pref.intolerances, ...pref.disliked];
            if (avoid.length) {
                lines.push(t(
                    `Avoid absolutely these ingredients and their derivatives: ${avoid.join(', ')}.`,
                    `Evita absolutamente estos ingredientes y sus derivados: ${avoid.join(', ')}.`
                ));
            }
            // Spiciness hints
            if (pref.diet.includes('spicy_low')) lines.push(t('Keep spiciness low.', 'Mantén el picante bajo.'));
            if (pref.diet.includes('spicy_medium')) lines.push(t('Use medium spiciness.', 'Usa picante medio.'));
            if (pref.diet.includes('spicy_high')) lines.push(t('Allow high spiciness.', 'Permite picante alto.'));
            if (pref.diet.includes('no_ultra_processed')) lines.push(t('Avoid ultra-processed foods.', 'Evita ultraprocesados.'));
            if (pref.diet.includes('organic')) lines.push(t('Prefer organic produce when possible.', 'Prefiere productos orgánicos cuando sea posible.'));
            if (pref.diet.includes('wholefoods')) lines.push(t('Favor whole foods and minimally processed ingredients.', 'Favorece comida real e ingredientes mínimamente procesados.'));
            if (pref.diet.includes('no_alcohol')) lines.push(t('Do not use alcohol in any form.', 'No uses alcohol en ninguna forma.'));
            lines.push(t(
                'The ingredient list MUST comply with all restrictions; if any conflict arises, replace or omit the offending ingredient and adapt the dish accordingly.',
                'La lista de ingredientes DEBE cumplir todas las restricciones; si hay conflicto, sustituye u omite el ingrediente problemático y adapta el plato en consecuencia.'
            ));
            return lines.join('\n');
        }

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
 ${timeRule}
 ${skillRule}
 ${describePrefs()}
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
            const errText = await chatRes.text().catch(() => "");
            throw new HttpsError("internal", `OpenAI chat failed: ${chatRes.status} ${errText}`);
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
                    const errText = await imgRes.text().catch(() => "");
                    console.warn("[images] generation failed:", imgRes.status, errText);
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
