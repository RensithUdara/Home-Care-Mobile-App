import 'package:flutter/material.dart';

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
        return const Color(0xFFFF6B35); // Vibrant orange instead of light yellow
      case 'Refrigerator':
        return const Color(0xFF10B981); // Emerald green
      case 'AirConditioner':
        return const Color(0xFF3B82F6); // Blue
      case 'WashingMachine':
        return const Color(0xFF8B5CF6); // Purple
      case 'Laptop':
        return const Color(0xFFF59E0B); // Amber/Orange
      case 'Speaker':
        return const Color(0xFFEF4444); // Red
      case 'VacuumCleaner':
        return const Color(0xFFEC4899); // Pink
      case 'Fan':
        return const Color(0xFF84CC16); // Lime green instead of yellow
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // New method for text colors that are visible in both light and dark modes
  static Color getTextColor(String type, bool isDarkMode) {
    if (isDarkMode) {
      // Bright colors for dark mode
      switch (type) {
        case 'Television':
          return const Color(0xFFFF8A65); // Light orange
        case 'Refrigerator':
          return const Color(0xFF4ADE80); // Light green
        case 'AirConditioner':
          return const Color(0xFF60A5FA); // Light blue
        case 'WashingMachine':
          return const Color(0xFFA78BFA); // Light purple
        case 'Laptop':
          return const Color(0xFFFBBF24); // Light amber
        case 'Speaker':
          return const Color(0xFFF87171); // Light red
        case 'VacuumCleaner':
          return const Color(0xFFF472B6); // Light pink
        case 'Fan':
          return const Color(0xFFA3E635); // Light lime
        default:
          return const Color(0xFF9CA3AF); // Light gray
      }
    } else {
      // Dark colors for light mode - using the same vibrant colors but darker shades
      switch (type) {
        case 'Television':
          return const Color(0xFFEA580C); // Dark orange
        case 'Refrigerator':
          return const Color(0xFF059669); // Dark green
        case 'AirConditioner':
          return const Color(0xFF2563EB); // Dark blue
        case 'WashingMachine':
          return const Color(0xFF7C3AED); // Dark purple
        case 'Laptop':
          return const Color(0xFFD97706); // Dark amber
        case 'Speaker':
          return const Color(0xFFDC2626); // Dark red
        case 'VacuumCleaner':
          return const Color(0xFFDB2777); // Dark pink
        case 'Fan':
          return const Color(0xFF65A30D); // Dark lime
        default:
          return const Color(0xFF4B5563); // Dark gray
      }
    }
  }

  static IconData getIconData(String type) {
    switch (type.toLowerCase()) {
      case 'television':
        return Icons.tv;
      case 'refrigerator':
        return Icons.kitchen;
      case 'airconditioner':
        return Icons.ac_unit;
      case 'washingmachine':
        return Icons.local_laundry_service;
      case 'laptop':
        return Icons.laptop_mac;
      case 'speaker':
        return Icons.speaker;
      case 'vacuumcleaner':
        return Icons.cleaning_services;
      case 'fan':
        return Icons.toys;
      default:
        return Icons.devices_other;
    }
  }
}
