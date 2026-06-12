# Casos de uso pendientes

Ya implementados (Fase 1): `sign_in_with_google_use_case.dart`,
`sign_in_with_email_use_case.dart`, `sign_up_with_email_use_case.dart`,
`sign_out_use_case.dart`, `get_current_user_use_case.dart`.

Pendientes (Fases 2-4), siguen el mismo patrón `BaseUseCase<P, T>`, sobre
Cloud Firestore (ver `firestore_remote_datasource_contract.dart`):
- `create_group_use_case.dart`
- `get_groups_use_case.dart` / `watch_groups_use_case.dart`
- `join_group_use_case.dart`
- `get_expenses_use_case.dart` / `watch_expenses_use_case.dart`
- `add_expense_use_case.dart`
- `edit_expense_use_case.dart`
- `delete_expense_use_case.dart`
- `import_csv_use_case.dart`
- `get_balances_use_case.dart`
- `calculate_balances_use_case.dart` (algoritmo puro Dart, sección 6 del plan)
- `settle_up_use_case.dart`
