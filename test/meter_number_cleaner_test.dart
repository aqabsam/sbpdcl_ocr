import 'package:flutter_test/flutter_test.dart';
import 'package:sbpdcl_ocr_app/utils/meter_number_cleaner.dart';

void main() {
  group('MeterNumberCleaner', () {
    test('normalizes raw meter serials', () {
      expect(MeterNumberCleaner.normalize(' SB-100234 '), 'SB100234');
      expect(MeterNumberCleaner.normalize('Sr. No: GP882910'), 'GP882910');
      expect(MeterNumberCleaner.normalize('Meter No. LT948201'), 'LT948201');
      expect(MeterNumberCleaner.normalize('S/N: SEC-77410'), 'SEC77410');
    });

    test('extracts serial candidates from simulated OCR multi-line text', () {
      const ocrOutput = '''
      SOUTH BIHAR POWER DISTRIBUTION
      PROPERTY OF SBPDCL
      3 PHASE 4 WIRE STATIC ENERGY METER
      TYPE: E3M10
      Sr No: SB100234
      240V 5-30A 50Hz
      KWH: 04921.8
      MADE IN INDIA 2022
      ''';

      final candidates = MeterNumberCleaner.extractCandidates(ocrOutput);

      expect(candidates, contains('SB100234'));
      expect(candidates, isNot(contains('SBPDCL')));
      expect(candidates, isNot(contains('KWH')));
      expect(candidates, isNot(contains('INDIA')));
    });

    test('prioritizes strong candidate patterns', () {
      const ocrOutput = '''
      METER NO: GP882910
      DATE 2023
      50HZ
      ''';

      final candidates = MeterNumberCleaner.extractCandidates(ocrOutput);
      expect(candidates.isNotEmpty, true);
      expect(candidates.first, 'GP882910');
    });
  });
}

