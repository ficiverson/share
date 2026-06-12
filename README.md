# Share

App tipo Splitwise (web + Flutter) para compartir gastos con amigos y
familia. Clean Architecture siguiendo el patrón de
[radiocom-flutter](https://github.com/ficiverson/radiocom-flutter). Sin
backend propio: cada grupo es un Google Sheets en el Drive de quien lo crea.

## Estado actual

Implementado (Fase 0 + Fase 1):
- Estructura de carpetas completa (`domain`, `data`, `local-data-source`,
  `remote-data-source`, `models`, `injector`, `ui`).
- Núcleo `Result` / `BaseUseCase` / `Invoker` / `UseCaseCallback`.
- Modelos: `AppUser`, `Group`, `Member`, `Expense`, `Split`, `Settlement`,
  `MemberBalance` / `DebtTransfer`.
- Autenticación con Google (`google_sign_in`): `AuthRepository`,
  datasources local (Hive) y remoto, casos de uso `sign_in`, `sign_out`,
  `get_current_user`.
- `DependencyInjector` (inyección manual, sin get_it/riverpod).
- UI MVP: pantalla de login (`ui/login`) y placeholder de "Mis grupos"
  (`ui/groups`).
- Contratos de repositorio/datasource para Fases 2-4 (grupos, gastos,
  balances) ya definidos en `domain/repository` y `data/datasource`, listos
  para implementar.

Pendiente (ver `PENDING.md`/`PENDING_USECASES.md` en cada carpeta): Fases
2-7 (grupos, gastos, balances, importación CSV, pulido, móvil).

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
4. Configura el proyecto OAuth en Google Cloud Console:
   - Crea un proyecto y habilita **Google Drive API** y **Google Sheets API**.
   - Crea credenciales OAuth 2.0 (tipo Web y, si aplica, Android/iOS).
   - Para Web: añade tu origen (p.ej. `http://localhost:PORT`) como "Authorized
     JavaScript origin" y configura el `meta tag` de `google_sign_in_web` en
     `web/index.html` con tu Client ID (`<meta name="google-signin-client_id"
     content="TU_CLIENT_ID.apps.googleusercontent.com">`).
   - Para Android: registra el SHA-1 de tu keystore de debug/release.
   - Scopes ya configurados en `auth_remote_datasource.dart`: `email`,
     `profile`, `drive.file`, `spreadsheets`.
5. Ejecuta:
   ```
   flutter run -d chrome
   ```

## Siguiente paso recomendado

Fase 2 (grupos): implementar `drive_remote_datasource.dart` y
`sheets_remote_datasource.dart` (creación de Spreadsheet + hojas, compartir
permisos), `GroupsRepository`, `groups_local_datasource.dart` y los casos de
uso `create_group`, `get_groups`, `join_group`, más la UI de `ui/groups`
(lista real) y `ui/group-detail`.
