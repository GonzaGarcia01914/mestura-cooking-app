## Cloud Functions (Backend)

Archivo principal: `functions/index.js`

Tecnología:

- Cloud Functions v2 (callable) en Node.js 22.
- Dependencias: `firebase-functions@^6`, `firebase-admin`.
- Secreto: `OPENAI_API_KEY` (Secret Manager) inyectado en runtime.
- App Check: no forzado (`enforceAppCheck: false`).

Región y opción comunes:

- `region: 'europe-west1'` (ajusta según despliegue)
- Timeout 60s, memoria 256MiB.

Endpoints callable:

- `isFood(data)`
  - Input: `{ query: string }`
  - Valida si el texto describe comida/comestible vía chat con modelo ligero.
  - Output: `"yes"/"no"` o boolean según parse; el cliente lo normaliza a boolean.

- `generateRecipe(data)`
  - Input principal:
    - `query: string` — ingrediente(s) o plato.
    - `language: string` — código o prefijo (`es`, `en`, ...).
    - `restrictions?: string[]` — evitar ingredientes.
    - `servings?: number` — raciones.
    - `generateImage?: boolean` — activar DALL·E 3.
    - `imageSize?: '1024x1024'|'...'
    - `includeMacros?: boolean` — añadir `nutrition`.
    - `maxCaloriesKcal?: number` — límite por ración si `includeMacros`.
    - `timeLimitMinutes?: number` — límite de tiempo total.
    - `skillLevel?: 'basic'|'standard'|'elevated'` — complejidad de técnicas.
    - `preferences?: object` — ver `FoodPreferences.toJson()`.
  - Comportamiento:
    - Construye prompts (system/user) con reglas duras de preferencias y formato JSON.
    - Llama a Chat Completions (`gpt-4o-mini`) con `response_format: json_object`.
    - Opcional: genera imagen con `dall-e-3`.
    - Moderación: entrada y salida con `omni-moderation-latest`.
  - Output (si éxito):
    ```json
    {
      "title": "...",
      "ingredients": ["..."],
      "steps": ["..."],
      "image": "https://..." | "",
      "servings": 2,
      "nutrition": { ... } | null
    }
    ```

Despliegue:

- `cd functions && npm install && npm run deploy`
- Asegura `firebase use <tu-proyecto>` y el secreto `OPENAI_API_KEY` accesible.

Emuladores:

- `npm run serve` para levantar Functions localmente.

Clientes:

- El cliente Flutter llama usando `FirebaseFunctions.instanceFor(region: ...)` con fallback (`OpenAIService._fallbackRegion = 'us-central1'`).

