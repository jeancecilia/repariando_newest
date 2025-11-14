import 'package:intl/intl.dart';

class AppConstants {
  static const String APP_NAME = 'Repariando';

  static final YEARS = List.generate(
    ((2025 - 1950) ~/ 5 + 1),
    (index) => (2025 - index * 5).toString(),
  );
  static const ENGINE_TYPES = [
    'Benzin',
    'Diesel',
    'Hybrid',
    'Elektrisch',
    'Erdgas',
  ];
  static const MILEAGE = [
    '0–1000 km',
    '1001–5000 km',
    '5001–100000 km',
    '100001–150000 km',
    '150001–200000 km',
    'über 200001 km',
  ];
}

final NumberFormat _germanCurrencyFormatter = NumberFormat.currency(
  locale: 'de_DE',
  symbol: '€',
  decimalDigits: 2,
);

/// Formats numeric or textual price inputs with the German currency locale.
///
/// The helper accepts [num] values (e.g. API doubles) as well as [String]
/// values that may already contain localization artefacts like `€`, spaces,
/// commas, or thousands separators. This makes the formatter resilient when
/// prices move through multiple serialization layers without affecting other
/// booking calculations.
String formatPrice(Object? price) {
  final numericPrice = _coercePrice(price);
  final formatted = _germanCurrencyFormatter.format(numericPrice);
  return formatted.replaceAll('\u00A0', ' ');
}

double _coercePrice(Object? price) {
  if (price == null) {
    return 0;
  }

  if (price is num) {
    return price.toDouble();
  }

  if (price is String) {
    final sanitized = price.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (sanitized.isEmpty) {
      return 0;
    }

    final lastCommaIndex = sanitized.lastIndexOf(',');
    final lastDotIndex = sanitized.lastIndexOf('.');

    if (lastCommaIndex > lastDotIndex) {
      final withoutThousands = sanitized.replaceAll('.', '');
      final normalizedDecimal = withoutThousands.replaceAll(',', '.');
      return double.tryParse(normalizedDecimal) ?? 0;
    }

    final normalized = sanitized.replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  return 0;
}
