import 'package:flutter/material.dart';

/// Mapea la categoría de un gasto (string libre de Splitwise u otro origen)
/// a un [IconData] de Material para mostrar en la lista de gastos.
class ExpenseCategory {
  ExpenseCategory._();

  /// Categorías predefinidas con su icono. El orden determina cómo aparecen en el formulario.
  static const Map<String, IconData> predefined = {
    'Comida': Icons.restaurant,
    'Bar': Icons.local_bar,
    'Hogar': Icons.chair,
    'Internet': Icons.wifi,
    'Mantenimiento': Icons.build,
    'Transporte': Icons.directions_car,
    'Ocio': Icons.movie,
    'Salud': Icons.medical_services,
    'Ropa': Icons.checkroom,
    'Viaje': Icons.flight,
    'Deporte': Icons.fitness_center,
    'Mascotas': Icons.pets,
    'Educación': Icons.school,
    'Finanzas': Icons.account_balance,
    'Regalos': Icons.card_giftcard,
    'Farmacia': Icons.local_pharmacy,
    'Limpieza': Icons.cleaning_services,
  };

  static IconData icon(String category) {
    final c = category.trim().toLowerCase();

    if (_matches(c, ['aliment', 'comida', 'mercado', 'supermercado', 'restaurante', 'cocina', 'cena', 'almuerzo', 'desayuno'])) {
      return Icons.restaurant;
    }
    if (_matches(c, ['licor', 'bar', 'birr', 'bebida', 'cerveza', 'vino', 'alcohol', 'copa'])) {
      return Icons.local_bar;
    }
    if (_matches(c, ['mueble', 'decoración', 'decoracion', 'hogar'])) {
      return Icons.chair;
    }
    if (_matches(c, ['tv', 'internet', 'teléfono', 'telefono', 'móvil', 'movil', 'cable', 'streaming', 'netflix', 'spotify'])) {
      return Icons.wifi;
    }
    if (_matches(c, ['mantenimiento', 'reparaci', 'reforma', 'obra', 'fontanero', 'electricista'])) {
      return Icons.build;
    }
    if (_matches(c, ['transport', 'gasolina', 'coche', 'taxi', 'uber', 'tren', 'metro', 'bus', 'autobús', 'autobus', 'avión', 'avion', 'vuelo', 'gasolinera'])) {
      return Icons.directions_car;
    }
    if (_matches(c, ['ocio', 'entretenimiento', 'cine', 'teatro', 'concierto', 'evento', 'fiesta', 'parque'])) {
      return Icons.movie;
    }
    if (_matches(c, ['salud', 'farmacia', 'medic', 'doctor', 'dentista', 'hospital', 'clínica', 'clinica'])) {
      return Icons.medical_services;
    }
    if (_matches(c, ['ropa', 'moda', 'calzado', 'zapato', 'tienda'])) {
      return Icons.checkroom;
    }
    if (_matches(c, ['viaje', 'hotel', 'alojamiento', 'airbnb', 'vuelo', 'turismo', 'vacacion'])) {
      return Icons.flight;
    }
    if (_matches(c, ['deporte', 'gimnasio', 'gym', 'sport', 'fitness', 'fútbol', 'futbol', 'pádel', 'padel'])) {
      return Icons.fitness_center;
    }
    if (_matches(c, ['mascota', 'veterinario', 'perro', 'gato', 'animal'])) {
      return Icons.pets;
    }
    if (_matches(c, ['educaci', 'libro', 'curso', 'universidad', 'colegio', 'escuela', 'matrícula', 'matricula'])) {
      return Icons.school;
    }
    if (_matches(c, ['seguro', 'impuesto', 'tasa', 'multa', 'banco', 'finanza'])) {
      return Icons.account_balance;
    }
    if (_matches(c, ['regalo', 'cumpleaños', 'cumpleanos', 'navidad'])) {
      return Icons.card_giftcard;
    }
    if (_matches(c, ['suplement', 'vitamina', 'proteína', 'proteina'])) {
      return Icons.local_pharmacy;
    }
    if (_matches(c, ['limpieza', 'producto'])) {
      return Icons.cleaning_services;
    }

    return Icons.receipt_long;
  }

  static bool _matches(String category, List<String> keywords) =>
      keywords.any((kw) => category.contains(kw));
}
