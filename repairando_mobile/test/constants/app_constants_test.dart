import 'package:flutter_test/flutter_test.dart';
import 'package:repairando_mobile/src/constants/app_constants.dart';

void main() {
  group('formatPrice', () {
    test('formats price with two decimals and comma separator', () {
      expect(formatPrice(25.9), '25,90 €');
    });

    test('formats integer price with trailing decimals', () {
      expect(formatPrice(25), '25,00 €');
    });

    test('formats zero price', () {
      expect(formatPrice(0), '0,00 €');
    });

    test('formats thousands with German separators', () {
      expect(formatPrice(1999), '1.999,00 €');
    });

    test('parses decimal strings with comma separators', () {
      expect(formatPrice('25,90'), '25,90 €');
    });

    test('parses decimal strings with dot separators', () {
      expect(formatPrice('25.90'), '25,90 €');
    });

    test('parses values containing the euro symbol', () {
      expect(formatPrice('  1.999,00 €  '), '1.999,00 €');
    });

    test('defaults to zero for unsupported values', () {
      expect(formatPrice('invalid'), '0,00 €');
    });
  });
}
