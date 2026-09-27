import 'package:flutter_test/flutter_test.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/reminder_service.dart';
import 'package:home_care/utils/warranty.dart';

Products _p({
  required DateTime warranty,
  DateTime? nextService,
  List<ServiceRecord>? history,
}) =>
    Products(
      uid: 'u',
      id: 'p1',
      name: 'AC',
      location: 'Bedroom',
      purchasedDate: DateTime(2024, 1, 1),
      warrantyPeriod: warranty,
      contactNumber: 1,
      type: Category.AirConditioner,
      nextServiceDate: nextService,
      serviceHistory: history,
    );

void main() {
  final now = DateTime(2026, 6, 1, 10); // 10:00 on June 1

  group('planReminders', () {
    test('schedules 30d, 7d and same-day warranty reminders at chosen hour',
        () {
      final r = planReminders([_p(warranty: DateTime(2026, 8, 1))],
          now: now, hour: 9);
      expect(r.map((e) => e.when), [
        DateTime(2026, 7, 2, 9),
        DateTime(2026, 7, 25, 9),
        DateTime(2026, 8, 1, 9),
      ]);
    });

    test('skips reminders already in the past', () {
      // 7-day mark (June 3) and 30-day mark (May 11) are handled correctly:
      // only the ones after "now" remain.
      final r = planReminders([_p(warranty: DateTime(2026, 6, 10))],
          now: now);
      expect(r.map((e) => e.when),
          [DateTime(2026, 6, 3, 9), DateTime(2026, 6, 10, 9)]);
    });

    test('same-day reminder is dropped once its hour has passed', () {
      final r = planReminders([_p(warranty: DateTime(2026, 6, 1))], now: now);
      expect(r, isEmpty);
    });

    test('includes service reminders and respects toggles', () {
      final p = _p(
          warranty: DateTime(2030, 1, 1), nextService: DateTime(2026, 6, 20));
      final both = planReminders([p], now: now);
      expect(both.where((e) => e.title.startsWith('Service')).length, 2);

      final serviceOnly = planReminders([p], now: now, warranty: false);
      expect(serviceOnly.every((e) => e.title.startsWith('Service')), isTrue);

      expect(planReminders([p], now: now, warranty: false, service: false),
          isEmpty);
    });

    test('results are sorted soonest first', () {
      final r = planReminders([
        _p(warranty: DateTime(2027, 1, 1)),
        _p(warranty: DateTime(2026, 7, 1)),
      ], now: now);
      for (var i = 1; i < r.length; i++) {
        expect(r[i].when.isBefore(r[i - 1].when), isFalse);
      }
    });
  });

  group('service status', () {
    final today = DateTime.now();
    DateTime inDays(int d) => DateTime(today.year, today.month, today.day + d);

    test('none, scheduled, due soon, overdue', () {
      expect(_p(warranty: inDays(900)).serviceStatus, ServiceStatus.none);
      expect(_p(warranty: inDays(900), nextService: inDays(30)).serviceStatus,
          ServiceStatus.scheduled);
      expect(_p(warranty: inDays(900), nextService: inDays(7)).serviceStatus,
          ServiceStatus.dueSoon);
      expect(_p(warranty: inDays(900), nextService: inDays(-1)).serviceStatus,
          ServiceStatus.overdue);
    });
  });

  group('service history persistence', () {
    test('round-trips records, favorite and next service, newest first', () {
      final p = _p(
        warranty: DateTime(2027, 1, 1),
        nextService: DateTime(2026, 9, 1),
        history: [
          ServiceRecord(date: DateTime(2025, 1, 1), title: 'Cleaning', cost: 40),
          ServiceRecord(
              date: DateTime(2026, 2, 1),
              title: 'Gas refill',
              cost: 60.5,
              provider: 'CoolFix'),
        ],
      )..isFavorite = true;

      final copy = Products.fromMap(p.toJSON(), p.id);
      expect(copy.isFavorite, isTrue);
      expect(copy.nextServiceDate, DateTime(2026, 9, 1));
      expect(copy.serviceHistory.map((r) => r.title),
          ['Gas refill', 'Cleaning']);
      expect(copy.serviceHistory.first.provider, 'CoolFix');
      expect(copy.maintenanceCost, 100.5);
    });

    test('legacy documents default to no history and not favorite', () {
      final p = Products.fromMap({
        'purchasedDate': '2024-01-01',
        'warrantyPeriod': '2025-01-01',
        'type': 'Fan',
      }, 'x');
      expect(p.isFavorite, isFalse);
      expect(p.nextServiceDate, isNull);
      expect(p.serviceHistory, isEmpty);
    });
  });
}
