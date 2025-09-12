## Estilo y Contribución

Objetivo: mantener un código claro, documentado y fácil de escalar.

Estilo de código:

- Usa las reglas de `flutter_lints` (ya incluidas) y `dart fix` cuando aplique.
- Nombres descriptivos; evita abreviaturas crípticas.
- Null-safety: prefiere tipos no nulos y valores por defecto razonables.
- Estructura por capas: modelos puros, servicios sin UI, UI declarativa sin lógica de negocio.

Comentarios y documentación:

- Documenta clases y métodos públicos con `///` explicando intención, parámetros y contratos.
- Incluye ejemplos breves cuando el uso no sea obvio.
- Para funciones complejas, añade una nota sobre invariantes y errores esperables.

Commits/PRs:

- Un cambio por PR, descripción clara del alcance y la motivación.
- Referencia archivos afectados y pruebas manuales realizadas.
- Evita formateos masivos no relacionados con el cambio.

Pruebas:

- Prioriza tests unitarios en `models/` y `utils/` y de servicios que no toquen red.
- Para servicios con plataforma/red, aísla lógica pura y considera mocks/fakes.

Generación de API docs (opcional):

- Puedes usar `dart doc` (o `flutter pub global run dartdoc`) para generar documentación a partir de comentarios `///`.
- No se incluye en CI por defecto; generar localmente cuando sea útil.

Guía de extensibilidad:

- Nuevo servicio: crea en `lib/core/services/`, añade proveedor en `core/providers.dart` si aplica, y documenta en `docs/servicios.md`.
- Nueva pantalla: en `lib/ui/screens/`, reutiliza widgets en `ui/widgets/` y define navegación en `core/navigation.dart` o router.
- Nuevas claves l10n: añade en ARB y usa `AppLocalizations`.

