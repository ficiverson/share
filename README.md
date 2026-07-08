# Share — Divide gastos en grupo

App tipo Splitwise para repartir gastos con amigos y familia. Funciona en **web, Android e iOS** desde el mismo código Flutter. El backend es **Firebase** (Authentication + Cloud Firestore), por lo que cada persona que clone este repo crea su propia instancia independiente con sus propios datos.

---

## Índice

1. [Requisitos previos](#1-requisitos-previos)
2. [Crear el proyecto Firebase](#2-crear-el-proyecto-firebase)
3. [Clonar y configurar el repo](#3-clonar-y-configurar-el-repo)
4. [Conectar Firebase a Flutter](#4-conectar-firebase-a-flutter)
5. [Configuración por plataforma](#5-configuración-por-plataforma)
   - [Web](#web)
   - [Android](#android)
   - [iOS](#ios)
6. [Reglas de seguridad de Firestore](#6-reglas-de-seguridad-de-firestore)
7. [Ejecutar en local](#7-ejecutar-en-local)
8. [Desplegar en web (Firebase Hosting)](#8-desplegar-en-web-firebase-hosting)
9. [Modelo de datos](#9-modelo-de-datos)

---

## 1. Requisitos previos

Instala las siguientes herramientas antes de empezar:

| Herramienta | Versión mínima | Descarga |
|---|---|---|
| Flutter SDK | 3.22+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.4+ | incluido con Flutter |
| Node.js | 18+ | https://nodejs.org |
| Firebase CLI | última | `npm install -g firebase-tools` |
| FlutterFire CLI | última | `dart pub global activate flutterfire_cli` |
| Git | cualquiera | https://git-scm.com |

Para iOS necesitas además un Mac con Xcode 15+ y CocoaPods:

```bash
sudo gem install cocoapods
```

Verifica que todo está bien:

```bash
flutter doctor
```

---

## 2. Crear el proyecto Firebase

### 2.1 Crear el proyecto

1. Ve a [console.firebase.google.com](https://console.firebase.google.com) e inicia sesión con tu cuenta de Google.
2. Haz clic en **Añadir proyecto**.
3. Elige un nombre (p.ej. `mi-share-app`) y sigue el wizard. Puedes desactivar Google Analytics si no lo necesitas.

### 2.2 Habilitar Authentication

1. En el menú lateral: **Compilación → Authentication → Comenzar**.
2. Ve a la pestaña **Método de inicio de sesión**.
3. Habilita los proveedores que quieras usar:
   - **Correo electrónico/contraseña** — siempre necesario.
   - **Google** — para login con Google (web + Android + iOS).
   - **Apple** — solo si quieres login con Apple en iOS.

### 2.3 Habilitar Cloud Firestore

1. **Compilación → Firestore Database → Crear base de datos**.
2. Selecciona **Iniciar en modo de producción** (las reglas de seguridad las pondremos en el paso 6).
3. Elige una región cercana a tus usuarios (p.ej. `europe-west1`).

### 2.4 Habilitar Firebase Hosting (solo para web)

1. **Compilación → Hosting → Comenzar** y sigue los pasos del wizard.
2. No hace falta configurar nada más aquí; lo haremos desde la CLI.

---

## 3. Clonar y configurar el repo

```bash
git clone https://github.com/TU_USUARIO/share.git
cd share
flutter pub get
```

---

## 4. Conectar Firebase a Flutter

Este es el paso más importante. FlutterFire CLI genera automáticamente el archivo `lib/firebase_options.dart` con las claves de **tu** proyecto Firebase.

```bash
# Inicia sesión en Firebase
firebase login

# Conecta el proyecto (ejecutar desde la raíz del repo)
flutterfire configure
```

El comando te pedirá:

- **Seleccionar proyecto**: elige el que creaste en el paso 2.
- **Plataformas**: selecciona las que necesites (`web`, `android`, `ios`).

Al terminar habrá generado/actualizado:

- `lib/firebase_options.dart` — configuración Dart (para todas las plataformas)
- `android/app/google-services.json` — configuración Android
- `ios/Runner/GoogleService-Info.plist` — configuración iOS

> ⚠️ **No compartas estos archivos** si tu repo es público. Añade `google-services.json` y `GoogleService-Info.plist` a `.gitignore`. `firebase_options.dart` solo contiene claves públicas del SDK pero por seguridad también puedes ignorarlo y que cada persona ejecute `flutterfire configure` en su máquina.

---

## 5. Configuración por plataforma

### Web

No necesita configuración adicional. El login con Google en web funciona con un popup gestionado directamente por Firebase sin paquetes extra. En web, por diseño, solo se muestra el formulario de email/contraseña (Google y Apple se ocultan automáticamente con `kIsWeb`).

Para probar en local:

```bash
flutter run -d chrome
```

---

### Android

#### 5.1 Cambiar el Application ID

Abre `android/app/build.gradle.kts` y cambia `com.example.share_app` por tu propio identificador:

```kotlin
android {
    namespace = "com.tudominio.shareapp"
    defaultConfig {
        applicationId = "com.tudominio.shareapp"
        // ...
    }
}
```

#### 5.2 Registrar el SHA-1 en Firebase

Google Sign-In en Android requiere que Firebase conozca la huella digital de tu keystore:

```bash
# Debug keystore (para desarrollo)
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

Copia el valor `SHA1` y pégalo en Firebase Console:
**Configuración del proyecto (⚙️) → tu app Android → Añadir huella digital**.

Después de añadirlo descarga el `google-services.json` actualizado y reemplázalo en `android/app/google-services.json`.

#### 5.3 Añadir google_sign_in

El login con Google en móvil requiere el paquete `google_sign_in`. Añádelo a `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
```

Luego abre `lib/remote-data-source/firebase/auth_remote_datasource.dart`, añade el import:

```dart
import 'package:google_sign_in/google_sign_in.dart';
```

Y reemplaza el bloque `if (!kIsWeb)` dentro de `signInWithGoogle()` con la implementación real:

```dart
if (!kIsWeb) {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) throw Exception('Cancelado por el usuario');
  final googleAuth = await googleUser.authentication;
  final credential = fb.GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  final userCredential = await _firebaseAuth.signInWithCredential(credential);
  final user = userCredential.user;
  if (user == null) throw Exception('No se pudo obtener el usuario');
  return AppUser.fromFirebaseUser(user);
}
```

---

### iOS

#### 5.1 Cambiar el Bundle ID

Abre `ios/Runner.xcworkspace` en Xcode:
1. Selecciona el target **Runner** en el panel izquierdo.
2. En la pestaña **General**, cambia el **Bundle Identifier** de `com.example.shareApp` a tu propio identificador (p.ej. `com.tudominio.shareapp`).

Debe coincidir con el Bundle ID que registraste en Firebase Console al añadir la app iOS.

#### 5.2 Configurar Google Sign-In en iOS

1. Descarga el `GoogleService-Info.plist` de Firebase Console (**Configuración del proyecto → tu app iOS**) y sustitúyelo en `ios/Runner/GoogleService-Info.plist`.

2. Abre el archivo y copia el valor de `REVERSED_CLIENT_ID` (tiene la forma `com.googleusercontent.apps.XXXXXX`).

3. En Xcode: **Runner → Info → URL Types → +** y pega el `REVERSED_CLIENT_ID` en el campo **URL Schemes**.

4. Añade `google_sign_in` al `pubspec.yaml` (igual que en la sección Android 5.3) y aplica la misma implementación en `auth_remote_datasource.dart`.

#### 5.3 Configurar Apple Sign-In en iOS

Apple Sign-In solo funciona en dispositivos Apple y requiere una cuenta de Apple Developer ($99/año).

1. En [developer.apple.com](https://developer.apple.com): **Certificates, IDs & Profiles → Identifiers → tu App ID** → activa **Sign In with Apple**.

2. En Firebase Console: **Authentication → Sign-in method → Apple** → configura con tu Service ID y las claves que Apple te proporciona.

3. En Xcode: **Runner → Signing & Capabilities → + Capability → Sign In with Apple**.

El código ya gestiona el flujo completo de Apple Sign-In con nonce seguro en `auth_remote_datasource.dart`.

#### 5.4 Instalar pods

```bash
cd ios
pod install
cd ..
```

---

## 6. Reglas de seguridad de Firestore

Aplica estas reglas en **Firebase Console → Firestore → Reglas** para que solo los miembros de un grupo puedan acceder a sus datos:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      // Crear grupo: el creador debe incluirse en memberIds
      allow create: if request.auth != null
        && request.auth.uid in request.resource.data.memberIds;

      // Leer y modificar: solo miembros actuales
      allow read, update: if request.auth != null
        && request.auth.uid in resource.data.memberIds;

      // Borrar: solo el creador
      allow delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;

      // Subcolecciones (expenses, settlements): solo miembros del grupo
      match /{subcollection=**}/{docId} {
        allow read, write: if request.auth != null
          && request.auth.uid in get(
            /databases/$(database)/documents/groups/$(groupId)
          ).data.memberIds;
      }
    }
  }
}
```

Haz clic en **Publicar** para activarlas.

---

## 7. Ejecutar en local

```bash
# Web
flutter run -d chrome

# Android (con emulador o dispositivo conectado por USB)
flutter run -d android

# iOS (solo en Mac con Xcode configurado)
flutter run -d ios

# Ver todos los dispositivos disponibles
flutter devices
```

---

## 8. Desplegar en web (Firebase Hosting)

### Primera vez

```bash
firebase init hosting
```

Responde al wizard:
- **Public directory**: `build/web`
- **Single-page app (rewrite all URLs to /index.html)**: `Yes`
- **Overwrite build/web/index.html**: `No`

### Publicar

```bash
flutter build web --release && firebase deploy --only hosting
```

Tu app quedará disponible en `https://TU-PROYECTO.web.app`.

### Dominio personalizado (opcional, también gratuito)

En Firebase Console → Hosting → **Añadir dominio personalizado** y sigue los pasos para verificar la propiedad del dominio y configurar los registros DNS.

---

## 9. Modelo de datos

La estructura de colecciones en Firestore:

```
groups/{groupId}
  ├── name: string
  ├── currency: string          ("EUR", "USD", …)
  ├── createdBy: string         (uid del creador)
  ├── createdAt: timestamp
  ├── memberIds: string[]       (array de uids — usado en reglas de seguridad)
  └── members: map[]
        ├── memberId: string
        ├── name: string
        ├── email: string
        ├── photoUrl: string
        ├── joinedAt: timestamp
        └── role: string        ("owner" | "member")

groups/{groupId}/expenses/{expenseId}
  ├── description: string
  ├── amount: number
  ├── currency: string
  ├── category: string
  ├── paidBy: string            (uid del pagador principal)
  ├── payments: map[]           (pagadores múltiples, vacío si paga uno solo)
  │     ├── memberId: string
  │     ├── shareAmount: number
  │     └── shareType: string
  ├── date: timestamp
  ├── createdAt: timestamp
  ├── createdBy: string
  ├── notes: string
  └── splits: map[]             (reparto entre miembros)
        ├── memberId: string
        ├── shareAmount: number
        └── shareType: string   ("equal" | "exact" | "percentage")

groups/{groupId}/settlements/{settlementId}
  ├── fromMemberId: string      (quien paga)
  ├── toMemberId: string        (quien cobra)
  ├── amount: number
  ├── currency: string
  ├── date: timestamp
  └── notes: string
```

---

## Funcionalidades

- **Autenticación**: email/contraseña en todas las plataformas; Google y Apple en móvil; solo email en web.
- **Grupos**: crear, unirse por ID, invitar miembros, editar nombre y moneda, salir, borrar.
- **Gastos**: añadir, editar, borrar; reparto igual o personalizado por miembro; pago único o compartido entre varios.
- **Balances**: cálculo automático de quién debe a quién con simplificación de deudas.
- **Liquidaciones**: registrar pagos entre miembros para saldar deudas.
- **CSV**: importar desde Splitwise, exportar gastos del grupo.
- **Estadísticas**: gráficas por categoría y por mes.
- **Modo oscuro**: automático según el sistema operativo.
- **Soporte offline**: Firestore persiste datos en caché local.

---

## Licencia

MIT
