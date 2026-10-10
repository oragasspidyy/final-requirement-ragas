import 'package:flutter_test/flutter_test.dart';
import 'package:petcarehub/data/catalog.dart';
import 'package:petcarehub/services/app_state.dart';

void main() {
  test('time slots parse into the right hour/minute', () {
    final d = DateTime(2026, 10, 8);
    expect(AppState.combine(d, '10:00 AM'), DateTime(2026, 10, 8, 10, 0));
    expect(AppState.combine(d, '2:30 PM'), DateTime(2026, 10, 8, 14, 30));
  });

  test('every service has an image and a price', () {
    for (final s in serviceCatalog) {
      expect(s.image, isNotEmpty);
      expect(s.price, greaterThan(0));
    }
  });
}
