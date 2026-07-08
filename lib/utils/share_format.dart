import 'package:intl/intl.dart';

/// Utilidades de formato para cantidades monetarias.
///
/// Uso: `ShareFormat.money(1234567.89, 'EUR')` → `'EUR 1.234.567,89'`
class ShareFormat {
  ShareFormat._();

  /// Formatea [amount] con separador de miles (.) y decimal (,) al estilo
  /// europeo/español, p.ej. `108.861,31`.
  /// El símbolo de moneda se añade como prefijo separado por un espacio.
  static String money(double amount, String currency) {
    final fmt = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '$currency ',
      decimalDigits: 2,
    );
    return fmt.format(amount);
  }

  /// Solo el número sin símbolo de moneda: `108.861,31`.
  static String amount(double amount) {
    final fmt = NumberFormat.decimalPatternDigits(
      locale: 'es_ES',
      decimalDigits: 2,
    );
    return fmt.format(amount);
  }
}
