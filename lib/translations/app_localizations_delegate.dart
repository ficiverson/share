import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// [LocalizationsDelegate] que proporciona [AppLocalizations] al árbol de
/// widgets. Regístralo en `localizationsDelegates` de [MaterialApp]:
///
/// ```dart
/// localizationsDelegates: const [
///   AppLocalizationsDelegate(),
///   GlobalMaterialLocalizations.delegate,
///   ...
/// ],
/// ```
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  /// Idiomas soportados: español (predeterminado) e inglés.
  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  /// `false` → no recarga si el locale no cambia (comportamiento estándar).
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
