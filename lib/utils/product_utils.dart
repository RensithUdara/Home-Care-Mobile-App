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
        return Colors.yellow.shade100.withOpacity(0.3);
      case 'Refrigerator':
        return Colors.greenAccent.shade100.withOpacity(0.3);
      case 'AirConditioner':
        return Colors.cyanAccent.shade100.withOpacity(0.3);
      case 'WashingMachine':
        return Colors.purpleAccent.shade100.withOpacity(0.3);
      case 'Laptop':
        return Colors.orangeAccent.shade100.withOpacity(0.3);
      case 'Speaker':
        return Colors.redAccent.shade100.withOpacity(0.3);
      case 'VacuumCleaner':
        return Colors.pinkAccent.shade100.withOpacity(0.3);
      case 'Fan':
        return Colors.yellowAccent.shade100.withOpacity(0.3);
      default:
        return Colors.grey.shade100
            .withOpacity(0.3); // Default color if type is not recognized
    }
  }

  // New method for text colors that are visible in both light and dark modes
  static Color getTextColor(String type, bool isDarkMode) {
    if (isDarkMode) {
      // Light colors for dark mode
      switch (type) {
        case 'Television':
          return Colors.yellow.shade300;
        case 'Refrigerator':
          return Colors.green.shade300;
        case 'AirConditioner':
          return Colors.cyan.shade300;
        case 'WashingMachine':
          return Colors.purple.shade300;
        case 'Laptop':
          return Colors.orange.shade300;
        case 'Speaker':
          return Colors.red.shade300;
        case 'VacuumCleaner':
          return Colors.pink.shade300;
        case 'Fan':
          return Colors.lime.shade300;
        default:
          return Colors.grey.shade300;
      }
    } else {
      // Dark colors for light mode
      switch (type) {
        case 'Television':
          return Colors.yellow.shade800;
        case 'Refrigerator':
          return Colors.green.shade800;
        case 'AirConditioner':
          return Colors.cyan.shade800;
        case 'WashingMachine':
          return Colors.purple.shade800;
        case 'Laptop':
          return Colors.orange.shade800;
        case 'Speaker':
          return Colors.red.shade800;
        case 'VacuumCleaner':
          return Colors.pink.shade800;
        case 'Fan':
          return Colors.lime.shade800;
        default:
          return Colors.grey.shade800;
      }
    }
  }
}
