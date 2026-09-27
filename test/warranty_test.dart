import 'package:flutter_test/flutter_test.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/utils/warranty.dart';

Products _product({
  String name = 'TV',
  required DateTime purchased,
  required DateTime warranty,
  double? price,
}) =>
    Products(
      uid: 'u1',
      id: name,
      name: name,
      location: 'Living room',
      purchasedDate: purchased,
      warrantyPeriod: warranty,
      contactNumber: 123,
      type: Category.Television,
      price: price,
    );

void main() {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day);

  group('warranty status', () {
    test('expired when end date has passed', () {
      final p = _product(
          purchased: d.subtract(const Duration(days: 400)),
          warranty: d.subtract(const Duration(days: 1)));
      expect(p.warrantyStatus, WarrantyStatus.expired);
      expect(p.daysLeft, -1);
      expect(p.warrantyElapsed, 1.0);
    });

    test('expiring soon within 30 days, including today', () {
      expect(
          _product(purchased: d.subtract(const Duration(days: 10)), warranty: d)
              .warrantyStatus,
          WarrantyStatus.expiringSoon);
      expect(
          _product(
                  purchased: d,
                  warranty: d.add(const Duration(days: kExpiringSoonDays)))
              .warrantyStatus,
          WarrantyStatus.expiringSoon);
    });

    test('active beyond 30 days', () {
      final p = _product(
          purchased: d.subtract(const Duration(days: 100)),
          warranty: d.add(const Duration(days: 100)));
      expect(p.warrantyStatus, WarrantyStatus.active);
      expect(p.warrantyElapsed, closeTo(0.5, 0.01));
    });
  });

  group('Products.fromMap', () {
    test('reads legacy documents without optional fields', () {
      final p = Products.fromMap({
        'uid': 'u1',
        'name': 'Fridge',
        'location': 'Kitchen',
        'purchasedDate': '2023-01-01T00:00:00.000',
        'warrantyPeriod': '2025-01-01T00:00:00.000',
        'contactNumber': 555,
        'type': 'Refrigerator',
      }, 'doc1');
      expect(p.id, 'doc1');
      expect(p.type, Category.Refrigerator);
      expect(p.brand, isNull);
      expect(p.price, isNull);
    });

    test('tolerates unknown type and string contact number', () {
      final p = Products.fromMap({
        'purchasedDate': '2023-01-01',
        'warrantyPeriod': '2024-01-01',
        'contactNumber': '0771234567',
        'type': 'Toaster',
        'price': 199,
        'brand': '  ',
      }, 'x');
      expect(p.type, Category.Other);
      expect(p.contactNumber, 771234567);
      expect(p.price, 199.0);
      expect(p.brand, isNull);
    });

    test('round-trips optional fields through toJSON', () {
      final original = _product(purchased: d, warranty: d, price: 49.5)
        ..brand = 'Sony'
        ..notes = 'Receipt in drawer';
      final copy = Products.fromMap(original.toJSON(), original.id);
      expect(copy.brand, 'Sony');
      expect(copy.notes, 'Receipt in drawer');
      expect(copy.price, 49.5);
    });
  });

  test('sorting by expiry puts soonest first', () {
    final a = _product(
        name: 'a', purchased: d, warranty: d.add(const Duration(days: 90)));
    final b = _product(
        name: 'b', purchased: d, warranty: d.add(const Duration(days: 5)));
    expect(ProductStore.sorted([a, b], ProductSort.expiry).first.name, 'b');
  });
}
