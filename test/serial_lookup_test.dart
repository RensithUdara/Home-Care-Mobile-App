import 'package:flutter_test/flutter_test.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/product_store.dart';

Products _p(String id, String? serial) => Products(
      uid: 'u',
      id: id,
      name: id,
      location: 'Home',
      purchasedDate: DateTime(2024),
      warrantyPeriod: DateTime(2026),
      contactNumber: 1,
      type: Category.Laptop,
      serialNumber: serial,
    );

void main() {
  final products = [
    _p('laptop', 'SN-4H7K 22Q9'),
    _p('tv', 'ABC12'),
    _p('fan', null),
  ];

  test('exact match ignoring case, spaces and punctuation', () {
    expect(findBySerial(products, 'sn4h7k22q9')?.id, 'laptop');
    expect(findBySerial(products, '  abc-12 ')?.id, 'tv');
  });

  test('matches when the scanned text contains the serial', () {
    expect(findBySerial(products, 'MODEL X100 / S/N: ABC12 / 2024')?.id, 'tv');
  });

  test('exact match wins over a partial one', () {
    final list = [_p('partial', 'ABC12'), _p('exact', 'XABC12Y')];
    expect(findBySerial(list, 'XABC12Y')?.id, 'exact');
  });

  test('no match, empty scan, and very short serials', () {
    expect(findBySerial(products, 'ZZZ999'), isNull);
    expect(findBySerial(products, '--'), isNull);
    // Serials under 5 chars only match exactly, to avoid false positives.
    expect(findBySerial([_p('short', 'A1')], 'XXA1XX'), isNull);
    expect(findBySerial([_p('short', 'A1')], 'a-1')?.id, 'short');
  });
}
