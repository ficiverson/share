import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/utils/share_colors.dart';

void main() {
  group('ShareColors', () {
    test('primary es el verde de la app', () {
      expect(ShareColors.primary, const Color(0xFF1CC29F));
    });

    test('primaryDark es más oscuro que primary', () {
      expect(ShareColors.primaryDark, const Color(0xFF0E8C72));
    });

    test('error es rojo', () {
      expect(ShareColors.error.red, greaterThan(200));
      expect(ShareColors.error.green, lessThan(100));
    });

    test('positive es verde oscuro', () {
      expect(ShareColors.positive.green, greaterThan(ShareColors.positive.red));
    });

    test('negative es rojo oscuro', () {
      expect(ShareColors.negative.red, greaterThan(ShareColors.negative.green));
    });

    test('theme() devuelve ThemeData con useMaterial3 = true', () {
      final theme = ShareColors.theme();
      expect(theme.useMaterial3, isTrue);
    });

    test('darkTheme() tiene brightness Brightness.dark', () {
      final theme = ShareColors.darkTheme();
      expect(theme.brightness, Brightness.dark);
    });

    test('theme() AppBar tiene fondo primary', () {
      final theme = ShareColors.theme();
      expect(theme.appBarTheme.backgroundColor, ShareColors.primary);
    });

    test('darkTheme() AppBar tiene fondo primaryDark', () {
      final theme = ShareColors.darkTheme();
      expect(theme.appBarTheme.backgroundColor, ShareColors.primaryDark);
    });
  });
}
