# Documentación del Proyecto

Bienvenido a Mestura (App Cocina). Esta carpeta reúne documentación técnica para entender, mantener y escalar el proyecto.

Contenido principal:

- Arquitectura general: `docs/arquitectura.md`
- Configuración y ejecución: `docs/configuracion.md`
- Servicios de la app (catálogo): `docs/servicios.md`
- Cloud Functions (API backend): `docs/functions.md`
- Internacionalización (l10n): `docs/l10n.md`
- Estilo y contribución: `docs/estilo_contribucion.md`

Puntos clave del stack:

- Flutter + Riverpod para UI y estado.
- Firebase: Auth anónima, Cloud Functions v2 (JS), Firestore (recipes compartidas), App Check.
- OpenAI vía Functions (secreto `OPENAI_API_KEY`).
- Almacenamiento local con `shared_preferences`.
- Ads con `google_mobile_ads` y una compuerta de frecuencia simple.
- Notificaciones locales y temporizadores (Android/iOS), con soporte de exact alarms en Android.
- Deep links con `app_links` y esquema personalizado `mestura://`.

Sigue por `docs/arquitectura.md` para entender el mapa del código y los flujos.

