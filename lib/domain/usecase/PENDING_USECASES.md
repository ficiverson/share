# Casos de uso pendientes

Ya implementados (Fase 1): `sign_in_with_google_use_case.dart`,
`sign_in_with_email_use_case.dart`, `sign_up_with_email_use_case.dart`,
`sign_out_use_case.dart`, `get_current_user_use_case.dart`.

Ya implementados (Fase 2 - grupos): `create_group_use_case.dart`,
`watch_groups_use_case.dart`, `join_group_use_case.dart`. UI real en
`ui/groups` (lista en tiempo real, crear grupo, unirse por ID) y
`ui/group-detail` (datos del grupo, ID para invitar, lista de miembros).

Ya implementados (Fase 3 - gastos): `watch_expenses_use_case.dart`,
`add_expense_use_case.dart`, `edit_expense_use_case.dart`,
`delete_expense_use_case.dart`, `import_csv_use_case.dart`. UI real en
`ui/expenses` (`expense_form_*`, accesible desde `ui/group-detail`, que
también lista los gastos en tiempo real, permite borrarlos y tiene un botón
para importar un CSV de Splitwise).

Pendientes (Fase 4), siguen el mismo patrón `BaseUseCase<P, T>`, sobre
Cloud Firestore (ver `firestore_remote_datasource_contract.dart`):
- `get_balances_use_case.dart`
- `calculate_balances_use_case.dart` (algoritmo puro Dart, sección 6 del plan)
- `settle_up_use_case.dart`
