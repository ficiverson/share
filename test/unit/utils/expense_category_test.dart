import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_app/utils/expense_category.dart';

void main() {
  group('ExpenseCategory.icon', () {
    test('comida → Icons.restaurant', () {
      expect(ExpenseCategory.icon('Comida'), Icons.restaurant);
      expect(ExpenseCategory.icon('restaurante'), Icons.restaurant);
      expect(ExpenseCategory.icon('Cena'), Icons.restaurant);
    });

    test('transporte → Icons.directions_car', () {
      expect(ExpenseCategory.icon('Transporte'), Icons.directions_car);
      expect(ExpenseCategory.icon('taxi'), Icons.directions_car);
      expect(ExpenseCategory.icon('uber'), Icons.directions_car);
    });

    test('viaje → Icons.flight', () {
      expect(ExpenseCategory.icon('Viaje'), Icons.flight);
      expect(ExpenseCategory.icon('hotel'), Icons.flight);
      expect(ExpenseCategory.icon('airbnb'), Icons.flight);
    });

    test('ocio → Icons.movie', () {
      expect(ExpenseCategory.icon('ocio'), Icons.movie);
      expect(ExpenseCategory.icon('cine'), Icons.movie);
    });

    test('salud → Icons.medical_services', () {
      expect(ExpenseCategory.icon('salud'), Icons.medical_services);
      expect(ExpenseCategory.icon('farmacia'), Icons.medical_services);
    });

    test('deporte → Icons.fitness_center', () {
      expect(ExpenseCategory.icon('deporte'), Icons.fitness_center);
      expect(ExpenseCategory.icon('gimnasio'), Icons.fitness_center);
    });

    test('mascota → Icons.pets', () {
      expect(ExpenseCategory.icon('mascota'), Icons.pets);
      expect(ExpenseCategory.icon('veterinario'), Icons.pets);
    });

    test('educación → Icons.school', () {
      expect(ExpenseCategory.icon('educación'), Icons.school);
      expect(ExpenseCategory.icon('libro'), Icons.school);
    });

    test('regalo → Icons.card_giftcard', () {
      expect(ExpenseCategory.icon('regalo'), Icons.card_giftcard);
      expect(ExpenseCategory.icon('cumpleaños'), Icons.card_giftcard);
    });

    test('hogar/mueble → Icons.chair', () {
      expect(ExpenseCategory.icon('mueble'), Icons.chair);
      expect(ExpenseCategory.icon('hogar'), Icons.chair);
    });

    test('wifi/internet → Icons.wifi', () {
      expect(ExpenseCategory.icon('internet'), Icons.wifi);
      expect(ExpenseCategory.icon('netflix'), Icons.wifi);
    });

    test('reparación → Icons.build', () {
      expect(ExpenseCategory.icon('mantenimiento'), Icons.build);
      expect(ExpenseCategory.icon('reparación'), Icons.build);
    });

    test('ropa → Icons.checkroom', () {
      expect(ExpenseCategory.icon('ropa'), Icons.checkroom);
      expect(ExpenseCategory.icon('moda'), Icons.checkroom);
    });

    test('finanzas → Icons.account_balance', () {
      expect(ExpenseCategory.icon('seguro'), Icons.account_balance);
      expect(ExpenseCategory.icon('impuesto'), Icons.account_balance);
    });

    test('limpieza → Icons.cleaning_services', () {
      expect(ExpenseCategory.icon('limpieza'), Icons.cleaning_services);
    });

    test('categoría desconocida → Icons.receipt_long', () {
      expect(ExpenseCategory.icon('xyz desconocido'), Icons.receipt_long);
      expect(ExpenseCategory.icon(''), Icons.receipt_long);
    });

    test('bar/alcohol → Icons.local_bar', () {
      expect(ExpenseCategory.icon('bar'), Icons.local_bar);
      expect(ExpenseCategory.icon('cerveza'), Icons.local_bar);
    });
  });
}
