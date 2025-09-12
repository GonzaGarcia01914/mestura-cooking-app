# Configuración y Ejecución

Requisitos:

- Flutter 3.x con Dart >= 3.7 (ver `pubspec.yaml`).
- Android Studio / Xcode según plataforma.
- Node.js (para Functions, Node 22) y Firebase CLI (`npm i -g firebase-tools`).

Dependencias del proyecto:

1) Instalar paquetes Flutter

   - `flutter pub get`

2) Inicializar Ads (opcional en desarrollo)

   - `AdService` usa IDs de prueba por defecto. Para producción, reemplaza por tus unidades de AdMob.

3) Configurar Firebase

   - Proyecto Firebase con: Auth anónima, Functions, Firestore, App Check (opcional en dev), y si se desea Dynamic Links.
   - Añade los ficheros de configuración de Firebase para Android/iOS/Web.

4) Secrets para Functions

   - Crea el secreto `OPENAI_API_KEY` en Google Secret Manager y vincúlalo a Functions.
   - Región por defecto: `europe-west1` (ajusta en `functions/index.js` y `OpenAIService._primaryRegion`).

Desarrollo local (emuladores):

- Functions:

  ```bash
  cd functions
  npm install
  npm run serve
  ```

Ejecución app:

- Dispositivo/emulador: `flutter run`.
- Web: requiere `ENABLE_FIREBASE_WEB=true` en defines y credenciales; ver guardas en `OpenAIService`.

Deep links (esquema personalizado):

- Esquema `mestura://recipe?id=...`. Configura intent filters (Android) y URL Types (iOS) para reconocer `mestura`.

Notas de despliegue:

- `cd functions && npm run deploy` (asegúrate de haber enlazado el proyecto con `firebase use`).
- Ver `docs/functions.md` para payloads y respuestas.

