import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules on-device reminders for warranty expiry and upcoming services.
///
/// Reminders are rebuilt from scratch on every [sync], so they always match
/// the current appliance list and the user's notification preferences.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const warrantyPrefKey = 'notif_warranty';
  static const servicePrefKey = 'notif_service';
  static const hourPrefKey = 'notif_hour';
  static const _permissionAskedKey = 'notif_permission_asked';

  /// Days before a warranty ends at which to remind the user.
  static const warrantyLeadDays = [30, 7, 0];

  /// Days before a service is due at which to remind the user.
  static const serviceLeadDays = [3, 0];

  // iOS allows at most 64 pending notifications per app.
  static const _maxPending = 60;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'home_care_reminders',
      'Reminders',
      channelDescription: 'Warranty expiry and service reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Reminder init failed: $e');
    }
  }

  /// Asks for notification permission once per install.
  Future<void> requestPermissionOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_permissionAskedKey) == true) return;
      await prefs.setBool(_permissionAskedKey, true);
      await requestPermission();
    } catch (_) {}
  }

  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> showTest() async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      id: 0,
      title: 'Reminders are on 🔔',
      body:
          'This is how Home Care will remind you about warranties and services.',
      notificationDetails: _details,
    );
  }

  /// Rebuilds every scheduled reminder for [products].
  Future<void> sync(List<Products> products) async {
    await init();
    if (!_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final warrantyOn = prefs.getBool(warrantyPrefKey) ?? true;
      final serviceOn = prefs.getBool(servicePrefKey) ?? true;
      final hour = prefs.getInt(hourPrefKey) ?? 9;

      final reminders = planReminders(
        products,
        now: DateTime.now(),
        hour: hour,
        warranty: warrantyOn,
        service: serviceOn,
      ).take(_maxPending);

      await _plugin.cancelAllPendingNotifications();
      var id = 1;
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: id++,
          // The instant is what matters, so UTC avoids needing the device's
          // named time zone.
          scheduledDate: tz.TZDateTime.from(r.when, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
          payload: r.productId,
        );
      }
    } catch (e) {
      debugPrint('Reminder sync failed: $e');
    }
  }
}

class PlannedReminder {
  final DateTime when;
  final String title;
  final String body;
  final String productId;
  const PlannedReminder(this.when, this.title, this.body, this.productId);
}

/// Pure planning step (no plugin calls) so it can be unit tested.
/// Returns future reminders only, soonest first.
List<PlannedReminder> planReminders(
  List<Products> products, {
  required DateTime now,
  int hour = 9,
  bool warranty = true,
  bool service = true,
}) {
  final out = <PlannedReminder>[];
  DateTime at(DateTime day, int daysBefore) =>
      DateTime(day.year, day.month, day.day - daysBefore, hour);

  for (final p in products) {
    if (warranty) {
      for (final lead in ReminderService.warrantyLeadDays) {
        final when = at(p.warrantyPeriod, lead);
        if (!when.isAfter(now)) continue;
        out.add(PlannedReminder(
          when,
          lead == 0
              ? 'Warranty ends today: ${p.name}'
              : 'Warranty ending in $lead days',
          lead == 0
              ? 'Last day to claim any repairs under warranty.'
              : '${p.name} (${p.location}) is covered until ${_d(p.warrantyPeriod)}. '
                  'Book any repairs before then.',
          p.id,
        ));
      }
    }
    final next = p.nextServiceDate;
    if (service && next != null) {
      for (final lead in ReminderService.serviceLeadDays) {
        final when = at(next, lead);
        if (!when.isAfter(now)) continue;
        out.add(PlannedReminder(
          when,
          lead == 0 ? 'Service due today' : 'Service due in $lead days',
          '${p.name} (${p.location}) is due for servicing'
          '${lead == 0 ? '' : ' on ${_d(next)}'}.',
          p.id,
        ));
      }
    }
  }
  out.sort((a, b) => a.when.compareTo(b.when));
  return out;
}

String _d(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Convenience used by the Warranty tab.
bool isServiceAlert(Products p) =>
    p.serviceStatus == ServiceStatus.dueSoon ||
    p.serviceStatus == ServiceStatus.overdue;
