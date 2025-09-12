# Catálogo de Servicios

Resumen de los servicios en `lib/core/services/` y sus responsabilidades.

OpenAIService — `lib/core/services/openai_service.dart`

- Autentica (Auth anónima) y asegura App Check cuando es posible.
- Llama a Cloud Functions callable: `isFood` y `generateRecipe` (fallback `openaiChat`).
- Normaliza respuestas (string o map) a `RecipeModel` y valida imagen/estructura.
- Flags opcionales: `timeLimitMinutes`, `skillLevel`, `includeMacros`, `maxCaloriesKcal`, `generateImage`.

Uso mínimo:

```dart
final api = OpenAIService();
final recipe = await api.generateRecipe(
  'Pasta con tomate',
  language: 'es',
  includeMacros: true,
);
```

StorageService — `lib/core/services/storage_service.dart`

- Guarda/lee recetas favoritas en `SharedPreferences` (`saved_recipes`).
- Evita duplicados por título.

ShoppingListService — `lib/core/services/shopping_list_service.dart`

- Persiste la lista de la compra en `SharedPreferences` (como JSON por item).

PreferencesService — `lib/core/services/preferences_service.dart`

- Carga/guarda `FoodPreferences` en `SharedPreferences` (`dietary_preferences_v1`).

AdService + AdGate — `lib/core/services/ad_service.dart`, `lib/core/services/ad_gate.dart`

- `AdService` gestiona interstitials (preload, show, reintentos exponenciales, logging seguro).
- `AdGate` lleva un contador simple para mostrar un ad cada N acciones (`every = 2`).

NotificationService — `lib/core/services/notification_service.dart`

- Inicializa notificaciones locales y timezones.
- `scheduleAlarm(...)` programa una alarma exacta/inexacta (maneja permisos Android 12+).
- `showOngoingCountdown(...)` muestra una notificación tipo cronómetro en curso.

DeepLinkService + ShareRecipeService — `lib/core/services/deeplink_service.dart`, `lib/core/services/share_recipe_service.dart`

- `ShareRecipeService.createShareLink(recipe)` almacena la receta en Firestore y devuelve `mestura://recipe?id=...`.
- `DeepLinkService.init()` escucha y maneja enlaces entrantes, navegando a `RecipeScreen` cuando hay un ID válido.

Navegación y providers — `lib/core/navigation.dart`, `lib/core/providers.dart`

- `appNavigatorKey` y helpers (`run_with_loading.dart`).
- Providers globales con Riverpod: `openAIServiceProvider`, `localeProvider`.

