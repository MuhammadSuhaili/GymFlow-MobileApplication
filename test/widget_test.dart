import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flow/core/utils/formatters.dart';
import 'package:gym_flow/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required rejects empty strings', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('Bench Press'), isNull);
    });

    test('positiveNumber rejects zero and negatives', () {
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-5'), isNotNull);
      expect(Validators.positiveNumber('42.5'), isNull);
    });
  });

  group('Formatters', () {
    test('duration formats minutes', () {
      expect(Formatters.duration(5), '5 min');
      expect(Formatters.duration(90), '1h 30m');
      expect(Formatters.duration(120), '2h');
    });

    test('volume uses tons above 1000', () {
      expect(Formatters.volumeKg(1500), '1.5t');
      expect(Formatters.volumeKg(250), '250 kg');
    });
  });
}