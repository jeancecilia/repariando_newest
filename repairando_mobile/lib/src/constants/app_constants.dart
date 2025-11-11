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

String formatPrice(double price) {
  if (price >= 100000) {
    // For 100000+: show as 1,20,000 format
    String formatted = (price / 100).toStringAsFixed(2).replaceAll('.', ',');
    return '${formatted.substring(0, formatted.length - 3)},${formatted.substring(formatted.length - 3)}€';
  } else if (price >= 1000) {
    // For 1000-99999: show as 10,00 format
    return '${(price / 100).toStringAsFixed(2).replaceAll('.', ',')}€';
  } else {
    // For under 1000: show raw number
    return '${price.toStringAsFixed(0)}€';
  }
}
