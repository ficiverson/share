import 'package:flutter/material.dart';

/// Strings localizados de la app en ES (predeterminado) y EN.
///
/// Uso en cualquier widget:
/// ```dart
/// final l = AppLocalizations.of(context);
/// Text(l.addExpense)
/// ```
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const _strings = <String, Map<String, String>>{
    'es': {
      // General
      'appTitle': 'Share',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Borrar',
      'confirm': 'Confirmar',
      'close': 'Cerrar',
      'copy': 'Copiar',
      'share': 'Compartir',
      'accept': 'Aceptar',
      'loading': 'Cargando…',
      'error': 'Error',
      'yes': 'Sí',
      'no': 'No',
      'all': 'Todos',
      'total': 'Total',
      'currency': 'Moneda',
      // Auth
      'login': 'Iniciar sesión',
      'loginGoogle': 'Continuar con Google',
      'loginApple': 'Continuar con Apple',
      'loginEmail': 'Continuar con email',
      'signOut': 'Cerrar sesión',
      'email': 'Email',
      'password': 'Contraseña',
      'name': 'Nombre',
      // Groups
      'groups': 'Grupos',
      'noGroups': 'No perteneces a ningún grupo todavía.',
      'createGroup': 'Crear grupo',
      'joinGroup': 'Unirse a grupo',
      'groupName': 'Nombre del grupo',
      'groupId': 'ID del grupo',
      'leaveGroup': 'Salir del grupo',
      'inviteMembers': 'Invitar a miembros',
      'members': 'Miembros',
      'copiedId': 'ID copiado',
      // Expenses
      'expenses': 'Gastos',
      'noExpenses': 'Todavía no hay gastos en este grupo.',
      'addExpense': 'Añadir gasto',
      'editExpense': 'Editar gasto',
      'deleteExpense': 'Borrar gasto',
      'deleteAllExpenses': 'Borrar todos los gastos',
      'description': 'Descripción',
      'amount': 'Importe',
      'category': 'Categoría',
      'paidBy': 'Pagado por',
      'date': 'Fecha',
      'notes': 'Notas',
      'importCsv': 'Importar CSV de Split-styler',
      'expenseDeleted': 'Gasto eliminado',
      'expenseSaved': 'Gasto guardado',
      // Balances
      'balances': 'Saldos',
      'settleUp': 'Liquidar',
      'settled': 'Liquidado',
      'totalSpent': 'Total gastado',
      'yourBalance': 'Tu balance',
      'youAreOwed': 'Te deben',
      'youOwe': 'Debes',
      'youAreEven': 'Estás al día',
    },
    'en': {
      // General
      'appTitle': 'Share',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'close': 'Close',
      'copy': 'Copy',
      'share': 'Share',
      'accept': 'Accept',
      'loading': 'Loading…',
      'error': 'Error',
      'yes': 'Yes',
      'no': 'No',
      'all': 'All',
      'total': 'Total',
      'currency': 'Currency',
      // Auth
      'login': 'Sign in',
      'loginGoogle': 'Continue with Google',
      'loginApple': 'Continue with Apple',
      'loginEmail': 'Continue with email',
      'signOut': 'Sign out',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      // Groups
      'groups': 'Groups',
      'noGroups': 'You don\'t belong to any group yet.',
      'createGroup': 'Create group',
      'joinGroup': 'Join group',
      'groupName': 'Group name',
      'groupId': 'Group ID',
      'leaveGroup': 'Leave group',
      'inviteMembers': 'Invite members',
      'members': 'Members',
      'copiedId': 'ID copied',
      // Expenses
      'expenses': 'Expenses',
      'noExpenses': 'No expenses in this group yet.',
      'addExpense': 'Add expense',
      'editExpense': 'Edit expense',
      'deleteExpense': 'Delete expense',
      'deleteAllExpenses': 'Delete all expenses',
      'description': 'Description',
      'amount': 'Amount',
      'category': 'Category',
      'paidBy': 'Paid by',
      'date': 'Date',
      'notes': 'Notes',
      'importCsv': 'Import Split-styler CSV',
      'expenseDeleted': 'Expense deleted',
      'expenseSaved': 'Expense saved',
      // Balances
      'balances': 'Balances',
      'settleUp': 'Settle up',
      'settled': 'Settled',
      'totalSpent': 'Total spent',
      'yourBalance': 'Your balance',
      'youAreOwed': 'You are owed',
      'youOwe': 'You owe',
      'youAreEven': 'You\'re all settled up',
    },
  };

  /// Devuelve el string localizado por [key]. Si no existe en el idioma actual
  /// cae al español; si tampoco existe allí, devuelve la propia [key].
  String t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['es']![key] ?? key;

  // Accesos con nombre —————————————————————————————————————————————————————
  String get appTitle => t('appTitle');
  String get cancel => t('cancel');
  String get save => t('save');
  String get delete => t('delete');
  String get confirm => t('confirm');
  String get close => t('close');
  String get copy => t('copy');
  String get share => t('share');
  String get loading => t('loading');
  String get error => t('error');
  String get total => t('total');
  String get currency => t('currency');

  String get login => t('login');
  String get loginGoogle => t('loginGoogle');
  String get loginApple => t('loginApple');
  String get loginEmail => t('loginEmail');
  String get signOut => t('signOut');
  String get email => t('email');
  String get password => t('password');
  String get name => t('name');

  String get groups => t('groups');
  String get noGroups => t('noGroups');
  String get createGroup => t('createGroup');
  String get joinGroup => t('joinGroup');
  String get groupName => t('groupName');
  String get groupId => t('groupId');
  String get leaveGroup => t('leaveGroup');
  String get inviteMembers => t('inviteMembers');
  String get members => t('members');
  String get copiedId => t('copiedId');

  String get expenses => t('expenses');
  String get noExpenses => t('noExpenses');
  String get addExpense => t('addExpense');
  String get editExpense => t('editExpense');
  String get deleteExpense => t('deleteExpense');
  String get deleteAllExpenses => t('deleteAllExpenses');
  String get description => t('description');
  String get amount => t('amount');
  String get category => t('category');
  String get paidBy => t('paidBy');
  String get date => t('date');
  String get notes => t('notes');
  String get importCsv => t('importCsv');
  String get expenseDeleted => t('expenseDeleted');
  String get expenseSaved => t('expenseSaved');

  String get balances => t('balances');
  String get settleUp => t('settleUp');
  String get settled => t('settled');
  String get totalSpent => t('totalSpent');
  String get yourBalance => t('yourBalance');
  String get youAreOwed => t('youAreOwed');
  String get youOwe => t('youOwe');
  String get youAreEven => t('youAreEven');
}
