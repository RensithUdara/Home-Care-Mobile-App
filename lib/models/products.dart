import 'package:cloud_firestore/cloud_firestore.dart';

class Products {
  String uid;
  String id;
  String name;
  String location;
  DateTime purchasedDate;
  DateTime warrantyPeriod;
  int contactNumber;
  Category type;

  // Optional details. Older documents simply don't have these fields.
  String? brand;
  String? serialNumber;
  double? price;
  String? notes;

  Products({
    required this.uid,
    required this.id,
    required this.name,
    required this.location,
    required this.purchasedDate,
    required this.contactNumber,
    required this.warrantyPeriod,
    required this.type,
    this.brand,
    this.serialNumber,
    this.price,
    this.notes,
  });

  // Convert a Products instance to a map
  Map<String, dynamic> toJSON() {
    return {
      'uid': uid,
      'id': id,
      'name': name,
      'location': location,
      'purchasedDate': _toDateOnly(purchasedDate),
      'warrantyPeriod': _toDateOnly(warrantyPeriod),
      'contactNumber': contactNumber,
      'type': type.toString().split('.').last, // Store enum as a string
      'brand': brand,
      'serialNumber': serialNumber,
      'price': price,
      'notes': notes,
    };
  }

  // Convert a Firestore document to a Products instance
  factory Products.fromMap(Map<String, dynamic> map, String id) {
    return Products(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      purchasedDate: _parseDate(map['purchasedDate']),
      warrantyPeriod: _parseDate(map['warrantyPeriod']),
      contactNumber: _parseInt(map['contactNumber']),
      type: Category.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => Category.Other,
      ),
      brand: _nonEmpty(map['brand']),
      serialNumber: _nonEmpty(map['serialNumber']),
      price: (map['price'] as num?)?.toDouble(),
      notes: _nonEmpty(map['notes']),
    );
  }

  Products copy() => Products.fromMap(toJSON(), id);

  // Helper method to format DateTime to date-only string
  String _toDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day)
        .toIso8601String();
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _nonEmpty(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

enum Category {
  Television,
  Refrigerator,
  AirConditioner,
  WashingMachine,
  Laptop,
  Speaker,
  VacuumCleaner,
  Fan,
  Other,
}
