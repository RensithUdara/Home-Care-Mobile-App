import 'package:flutter/material.dart';
import 'package:home_care/models/products.dart';
import 'package:intl/intl.dart';

class ProductUtils {
  static String getDisplayName(String name) {
    if (name.length > 17) {
      return '${name.substring(0, 15)}..';
    } else {
      return name;
    }
  }

  static String getTypeName(String type) {
    return type.split('.').last;
  }

  static String typeKey(Category category) =>
      category.toString().split('.').last;

  /// Human-friendly category label, e.g. "Air Conditioner".
  static String categoryName(Category category) => switch (category) {
        Category.AirConditioner => 'Air Conditioner',
        Category.WashingMachine => 'Washing Machine',
        Category.VacuumCleaner => 'Vacuum Cleaner',
        _ => typeKey(category),
      };

  static String getImagePath(String type) {
    switch (type) {
      case 'Television':
        return 'images/tv.png';
      case 'Refrigerator':
        return 'images/fridge.png';
      case 'AirConditioner':
        return 'images/ac.png';
      case 'WashingMachine':
        return 'images/wm.png';
      case 'Laptop':
        return 'images/laptop.png';
      case 'Speaker':
        return 'images/speaker.png';
      case 'VacuumCleaner':
        return 'images/vaccum.png';
      case 'Fan':
        return 'images/fan.png';
      default:
        return 'images/other.png'; // Default image if type is not recognized
    }
  }

  static Color getColor(String type) {
    switch (type) {
      case 'Television':
        return const Color(0xFFFF6B35);
      case 'Refrigerator':
        return const Color(0xFF10B981);
      case 'AirConditioner':
        return const Color(0xFF3B82F6);
      case 'WashingMachine':
        return const Color(0xFF8B5CF6);
      case 'Laptop':
        return const Color(0xFFF59E0B);
      case 'Speaker':
        return const Color(0xFFEF4444);
      case 'VacuumCleaner':
        return const Color(0xFFEC4899);
      case 'Fan':
        return const Color(0xFF84CC16);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color colorOf(Category category) => getColor(typeKey(category));

  static IconData getIconData(String type) {
    switch (type.toLowerCase()) {
      case 'television':
        return Icons.tv_rounded;
      case 'refrigerator':
        return Icons.kitchen_rounded;
      case 'airconditioner':
        return Icons.ac_unit_rounded;
      case 'washingmachine':
        return Icons.local_laundry_service_rounded;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'vacuumcleaner':
        return Icons.cleaning_services_rounded;
      case 'fan':
        return Icons.toys_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  static IconData iconOf(Category category) => getIconData(typeKey(category));

  static String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

  static String formatMoney(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 10000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
  }

  /// Plain-text summary used by the "copy details" action.
  static String shareText(Products p) {
    final lines = <String>[
      p.name,
      'Category: ${categoryName(p.type)}',
      if (p.brand != null) 'Brand: ${p.brand}',
      if (p.serialNumber != null) 'Serial: ${p.serialNumber}',
      'Location: ${p.location}',
      'Purchased: ${formatDate(p.purchasedDate)}',
      'Warranty until: ${formatDate(p.warrantyPeriod)}',
      if (p.price != null) 'Price: ${formatMoney(p.price!)}',
      'Support: ${p.contactNumber}',
      if (p.nextServiceDate != null)
        'Next service: ${formatDate(p.nextServiceDate!)}',
      if (p.serviceHistory.isNotEmpty)
        'Service records: ${p.serviceHistory.length}'
            '${p.maintenanceCost > 0 ? ' (${formatMoney(p.maintenanceCost)} spent)' : ''}',
      if (p.notes != null) 'Notes: ${p.notes}',
    ];
    return lines.join('\n');
  }
}
