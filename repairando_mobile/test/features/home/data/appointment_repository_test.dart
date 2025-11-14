import 'package:flutter_test/flutter_test.dart';
import 'package:repairando_mobile/src/features/home/data/appointment_repository.dart'
    show convertWorkUnitToMinutesOrNull;

void main() {
  group('convertWorkUnitToMinutesOrNull', () {
    test('returns null when value is null or empty', () {
      expect(convertWorkUnitToMinutesOrNull(null), isNull);
      expect(convertWorkUnitToMinutesOrNull(''), isNull);
      expect(convertWorkUnitToMinutesOrNull('   '), isNull);
    });

    test('converts valid work units into minutes using 6-minute factor', () {
      expect(convertWorkUnitToMinutesOrNull('5'), 30);
      expect(convertWorkUnitToMinutesOrNull('10'), 60);
      expect(convertWorkUnitToMinutesOrNull('2.5'), 15);
    });

    test('returns null for non-numeric values to allow fallback handling', () {
      expect(convertWorkUnitToMinutesOrNull('abc'), isNull);
      expect(convertWorkUnitToMinutesOrNull('10a'), isNull);
    });
  });
}
