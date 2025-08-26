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
}
