# Arquitectura

Visión por capas y responsabilidades principales del código en `lib/`:

- core/
  - localization/: utilidades l10n.
  - navigation/: helpers de navegación (p. ej., run_with_loading).
  - services/: integración con backend, persistencia local, ads, notificaciones, deep links.
  - theme/: theming de la app.
- models/: modelos puros (receta, preferencias, compra).
- ui/: pantallas, widgets reutilizables, estilo y helpers responsive.
- utils/: utilidades varias (builders, validadores, etc.).
- l10n/: ARB y clases generadas de localización.

Puntos de entrada:

- `lib/main.dart`: arranque de Flutter y providers globales.
- `lib/app.dart`: MaterialApp, tema y localización.

Estado y DI:

- Riverpod (`lib/core/providers.dart`) expone `openAIServiceProvider` y un `localeProvider`.

Modelos de datos:

- Receta y nutrición: `lib/models/recipe.dart`
- Preferencias de alimentación: `lib/models/preferences.dart`
- Item de compra: `lib/models/shopping_item.dart`

Servicios (resumen):

- OpenAIService: `lib/core/services/openai_service.dart` — orquesta llamadas a Cloud Functions (`isFood`, `generateRecipe`) y normaliza respuesta a `RecipeModel`.
- StorageService: `lib/core/services/storage_service.dart` — guarda/lee recetas en `SharedPreferences`.
- ShoppingListService: `lib/core/services/shopping_list_service.dart` — lista de la compra en local.
- PreferencesService: `lib/core/services/preferences_service.dart` — persistencia de preferencias del usuario.
- AdService + AdGate: `lib/core/services/ad_service.dart`, `lib/core/services/ad_gate.dart` — interstitials y frecuencia.
- NotificationService: `lib/core/services/notification_service.dart` — programación de alarmas y countdown ongoing.
- DeepLinkService + ShareRecipeService: `lib/core/services/deeplink_service.dart`, `lib/core/services/share_recipe_service.dart` — compartir/abrir recetas vía `mestura://recipe?id=...` almacenadas en Firestore.

Flujo principal (generar receta):

1) El usuario introduce una consulta en `HomeScreen` (`lib/ui/screens/home_screen.dart`).
2) `OpenAIService.generateRecipe(...)` envía la petición a la Function `generateRecipe` con restricciones e idioma, incluyendo preferencias guardadas.
3) La Function llama a OpenAI (chat e imagen opcional), valida/modera y devuelve JSON con título, ingredientes, pasos e info nutricional opcional.
4) La app parsea a `RecipeModel` y navega a `RecipeScreen`.
5) `AdGate` decide si mostrar un interstitial según la frecuencia.
6) El usuario puede guardar, compartir la receta (link deep) o añadir a la lista de la compra.

Backend (Functions v2):

- Archivo: `functions/index.js`. Endpoints callable `isFood` y `generateRecipe` (JS, Node 22). Requiere secreto `OPENAI_API_KEY` en Secret Manager. Región por defecto `europe-west1`.

Escalabilidad y separación de concerns:

- Lógica de negocio en servicios puros (testables) y UI delgada.
- Backend especializado para IA y moderación, desacoplado del cliente.
- Persistencia local simple para offline/rápida UX; Firestore solo para compartir.
- i18n separada con ARB para facilitar nuevas lenguas.

