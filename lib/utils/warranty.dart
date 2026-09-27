import 'package:flutter/material.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/themes/app_colors.dart';

/// Warranties ending within this many days count as "expiring soon".
const int kExpiringSoonDays = 30;

enum WarrantyStatus { active, expiringSoon, expired }

extension WarrantyStatusX on WarrantyStatus {
  String get label => switch (this) {
        WarrantyStatus.active => 'Active',
        WarrantyStatus.expiringSoon => 'Expiring soon',
        WarrantyStatus.expired => 'Expired',
      };

  Color get color => switch (this) {
        WarrantyStatus.active => AppColors.success,
        WarrantyStatus.expiringSoon => AppColors.warning,
        WarrantyStatus.expired => AppColors.danger,
      };

  IconData get icon => switch (this) {
        WarrantyStatus.active => Icons.verified_rounded,
        WarrantyStatus.expiringSoon => Icons.schedule_rounded,
        WarrantyStatus.expired => Icons.gpp_bad_rounded,
      };
}

extension ProductWarranty on Products {
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Whole days until the warranty ends; negative once it has expired.
  int get daysLeft {
    final end =
        DateTime(warrantyPeriod.year, warrantyPeriod.month, warrantyPeriod.day);
    return end.difference(_today).inDays;
  }

  WarrantyStatus get warrantyStatus {
    final days = daysLeft;
    if (days < 0) return WarrantyStatus.expired;
    if (days <= kExpiringSoonDays) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  /// Fraction of the warranty that has elapsed, clamped to 0..1.
  double get warrantyElapsed {
    final total = warrantyPeriod.difference(purchasedDate).inDays;
    if (total <= 0) return 1;
    final used = _today.difference(purchasedDate).inDays;
    return (used / total).clamp(0.0, 1.0);
  }

  int get ageInDays => _today.difference(purchasedDate).inDays;

  String get daysLeftLabel {
    final days = daysLeft;
    if (days < 0) return 'Expired ${_humanize(-days)} ago';
    if (days == 0) return 'Expires today';
    return '${_humanize(days)} left';
  }

  String get ageLabel {
    final days = ageInDays;
    if (days <= 0) return 'New';
    return _humanize(days);
  }
}

String _humanize(int days) {
  if (days >= 365) {
    final years = days / 365;
    final rounded =
        years >= 10 ? years.round().toString() : years.toStringAsFixed(1);
    return '${rounded.replaceAll('.0', '')} yr${years >= 1.05 ? 's' : ''}';
  }
  if (days >= 60) return '${(days / 30).round()} mo';
  return '$days day${days == 1 ? '' : 's'}';
}

/// Services due within this many days are flagged as "due soon".
const int kServiceDueSoonDays = 7;

enum ServiceStatus { none, scheduled, dueSoon, overdue }

extension ServiceStatusX on ServiceStatus {
  String get label => switch (this) {
        ServiceStatus.none => 'Not scheduled',
        ServiceStatus.scheduled => 'Scheduled',
        ServiceStatus.dueSoon => 'Due soon',
        ServiceStatus.overdue => 'Overdue',
      };

  Color get color => switch (this) {
        ServiceStatus.none => AppColors.lightTextMuted,
        ServiceStatus.scheduled => AppColors.info,
        ServiceStatus.dueSoon => AppColors.warning,
        ServiceStatus.overdue => AppColors.danger,
      };
}

extension ProductService on Products {
  /// Days until the next scheduled service; null when none is set.
  int? get serviceDaysLeft {
    final next = nextServiceDate;
    if (next == null) return null;
    final now = DateTime.now();
    return DateTime(next.year, next.month, next.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  ServiceStatus get serviceStatus {
    final days = serviceDaysLeft;
    if (days == null) return ServiceStatus.none;
    if (days < 0) return ServiceStatus.overdue;
    if (days <= kServiceDueSoonDays) return ServiceStatus.dueSoon;
    return ServiceStatus.scheduled;
  }

  String get serviceLabel {
    final days = serviceDaysLeft;
    if (days == null) return 'No service scheduled';
    if (days < 0) return 'Service overdue by ${_humanize(-days)}';
    if (days == 0) return 'Service due today';
    return 'Service in ${_humanize(days)}';
  }
}
