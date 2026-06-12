# Share

App tipo Splitwise (web + Flutter) para compartir gastos con amigos y
familia. Clean Architecture siguiendo el patrón de
[radiocom-flutter](https://github.com/ficiverson/radiocom-flutter). Backend:
**Firebase** (Authentication + Cloud Firestore).

## Estado actual

Implementado (Fase 0 + Fase 1 + Fase 2 + Fase 3):
- Estructura de carpetas completa (`domain`, `data`, `remote-data-source`,
  `models`, `injector`, `ui`).
- Núcleo `Result` / `BaseUseCase` / `Invoker` / `UseCaseCallback`.
- Modelos: `AppUser`, `Group`, `Member`, `Expense`, `Split`, `Settlement`,
  `MemberBalance` / `DebtTransfer` — con `toMap`/`fromMap` para Firestore.
- Autenticación con **Firebase Auth**: Google Sign-In (`google_sign_in` solo
  para obtener credenciales) y email/contraseña. `AuthRepository`,
  `AuthRemoteDataSource`, casos de uso `sign_in_with_google`,
  `sign_in_with_email`, `sign_up_with_email`, `sign_out`, `get_current_user`.
- `DependencyInjector` (inyección manual, sin get_it/riverpod), inicializa
  Firebase (`Firebase.initializeApp`).
- UI MVP: pantalla de login (`ui/login`, con Google + email/contraseña +
  registro).
- Grupos sobre Cloud Firestore: `FirestoreRemoteDataSource`,
  `GroupsRepository`, casos de uso `create_group`, `watch_groups`,
  `join_group`. UI real en `ui/groups` (lista en tiempo real de los grupos
  del usuario, crear grupo, unirse a uno existente por su ID) y
  `ui/group-detail` (datos del grupo, ID para invitar, lista de miembros).
- Gastos sobre Cloud Firestore (`groups/{groupId}/expenses`):
  `FirestoreRemoteDataSource` (CRUD + batch), `ExpensesRepository`, casos de
  uso `watch_expenses`, `add_expense`, `edit_expense`, `delete_expense`,
  `import_csv`. UI real en `ui/group-detail` (lista de gastos en tiempo
  real, borrar con pulsación larga) y `ui/expenses` (formulario de
  alta/edición con reparto a partes iguales entre los miembros
  seleccionados). Botón "Importar CSV" en `ui/group-detail` que usa
  `file_picker` para leer un CSV exportado de Splitwise y crear un gasto por
  fila (ver detalles del mapeo de columnas en
  `lib/data/expenses_repository.dart`).
- Contratos de repositorio/datasource para la Fase 4 (balances/
  liquidaciones) ya definidos en `domain/repository/balances_repository_contract.dart`
  y `data/datasource/firestore_remote_datasource_contract.dart`, modelados
  sobre la subcolección `groups/{groupId}/settlements` (`addSettlement` y
  `watchSettlements` ya implementados en el datasource).

Pendiente (ver `PENDING.md`/`PENDING_USECASES.md` en cada carpeta): Fases
4-7 (balances/liquidaciones, pulido, móvil).

## Modelo de datos en Firestore

- `groups/{groupId}`: `name`, `currency`, `createdBy`, `createdAt`,
  `memberIds` (array de uids, usado en las reglas de seguridad) y `members`
  (mapa `uid -> {name, email, photoUrl, joinedAt}`).
- `groups/{groupId}/expenses/{expenseId}`: `description`, `amount`,
  `currency`, `category`, `paidBy`, `date`, `createdAt`, `notes`, `splits`
  (array de `{memberId, shareAmount, shareType}`).
- `groups/{groupId}/settlements/{settlementId}`: `fromMemberId`,
  `toMemberId`, `amount`, `date`, `notes`.

Reglas de seguridad recomendadas (esbozo): solo usuarios autenticados que
estén en `memberIds` pueden leer/escribir un grupo y sus subcolecciones.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      allow read, update: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.memberIds;

      match /{subcollection=**}/{docId} {
        allow read, write: if request.auth != null &&
          request.auth.uid in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
      }
    }
  }
}
```

## Cómo continuar

Este entorno no tiene el SDK de Flutter instalado, así que el proyecto se ha
creado a mano (no con `flutter create`). Para abrirlo y ejecutarlo en tu
máquina:

1. Asegúrate de tener Flutter instalado (`flutter --version`).
2. Genera los archivos de plataforma que faltan (android/ios/web/etc.), por
   ejemplo ejecutando, **desde la raíz del proyecto**:
   ```
   flutter create .
   ```
   Esto añadirá las carpetas `android/`, `ios/`, `web/`, etc. sin tocar
   `lib/` ni `pubspec.yaml` (puede pedirte confirmar sobrescritura de algún
   archivo de config; revisa el diff si tienes dudas).
3. Instala dependencias:
   ```
   flutter pub get
   ```
4. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/):
   - Habilita **Authentication** → proveedores **Google** y
     **Email/contraseña**.
   - Habilita **Cloud Firestore** (modo producción) y aplica las reglas de
     seguridad de la sección anterior (ajustándolas a tus necesidades).
   - Registra tus apps (Web/Android/iOS) en el proyecto de Firebase.
5. Genera la configuración real de Firebase (sustituye el placeholder
   `lib/firebase_options.dart`):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
6. Para Google Sign-In:
   - Web: en Firebase Console, copia el "Web client ID" del proveedor Google
     y añádelo como `<meta name="google-signin-client_id" content="...">`
     en `web/index.html`.
   - Android: registra el SHA-1/SHA-256 de tu keystore en Firebase Console
     (Configuración del proyecto → tu app Android) para que Google Sign-In
     funcione.
7. Ejecuta:
   ```
   flutter run -d chrome
   ```

## Siguiente paso recomendado

Fase 4 (balances y liquidaciones): implementar `BalancesRepository`
(`getBalances` a partir de `expenses` + `splits` + `settlements`,
`watchSettlements`, `settleUp` ya soportado por el datasource), el algoritmo
`calculate_balances_use_case.dart` (sección 6 del plan: balance neto por
miembro y simplificación de deudas con `DebtTransfer`), y la UI de
`ui/balances` (pantalla "quién debe a quién" + registro de liquidaciones),
accesible desde `ui/group-detail`.
