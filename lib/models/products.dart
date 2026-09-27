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
  String? householdId;
  String? brand;
  String? serialNumber;
  double? price;
  String? notes;
  bool isFavorite;
  DateTime? nextServiceDate;
  List<ServiceRecord> serviceHistory;
  List<ProductDocument> documents;

  Products({
    required this.uid,
    required this.id,
    required this.name,
    required this.location,
    required this.purchasedDate,
    required this.contactNumber,
    required this.warrantyPeriod,
    required this.type,
    this.householdId,
    this.brand,
    this.serialNumber,
    this.price,
    this.notes,
    this.isFavorite = false,
    this.nextServiceDate,
    List<ServiceRecord>? serviceHistory,
    List<ProductDocument>? documents,
  })  : serviceHistory = serviceHistory ?? [],
        documents = documents ?? [];

  bool get hasReceipt => documents.any(
      (d) => d.type == DocumentType.receipt || d.type == DocumentType.invoice);

  /// Total spent on recorded repairs and servicing.
  double get maintenanceCost =>
      serviceHistory.fold(0.0, (total, r) => total + (r.cost ?? 0));

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
      'householdId': householdId,
      'brand': brand,
      'serialNumber': serialNumber,
      'price': price,
      'notes': notes,
      'isFavorite': isFavorite,
      'nextServiceDate':
          nextServiceDate == null ? null : _toDateOnly(nextServiceDate!),
      'serviceHistory': serviceHistory.map((r) => r.toJSON()).toList(),
      'documents': documents.map((d) => d.toJSON()).toList(),
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
      householdId: _nonEmpty(map['householdId']),
      brand: _nonEmpty(map['brand']),
      serialNumber: _nonEmpty(map['serialNumber']),
      price: (map['price'] as num?)?.toDouble(),
      notes: _nonEmpty(map['notes']),
      isFavorite: map['isFavorite'] == true,
      nextServiceDate: map['nextServiceDate'] == null
          ? null
          : _parseDate(map['nextServiceDate']),
      serviceHistory: (map['serviceHistory'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ServiceRecord.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
      documents: (map['documents'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ProductDocument.fromMap(Map<String, dynamic>.from(m)))
          .where((d) => d.url.isNotEmpty)
          .toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt)),
    );
  }

  Products copy() => Products.fromMap(toJSON(), id);

  // Helper method to format DateTime to date-only string
  String _toDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day)
        .toIso8601String();
  }

  static DateTime parseDate(dynamic value) => _parseDate(value);

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

enum DocumentType { receipt, warrantyCard, invoice, manual, photo, other }

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
        DocumentType.receipt => 'Receipt',
        DocumentType.warrantyCard => 'Warranty card',
        DocumentType.invoice => 'Invoice',
        DocumentType.manual => 'Manual',
        DocumentType.photo => 'Photo',
        DocumentType.other => 'Other',
      };
}

/// A photo of a receipt, warranty card, manual, etc. stored in Firebase
/// Storage at [path] and viewable at [url].
class ProductDocument {
  final String id;
  final DocumentType type;
  final String url;
  final String path;
  final DateTime addedAt;

  const ProductDocument({
    required this.id,
    required this.type,
    required this.url,
    required this.path,
    required this.addedAt,
  });

  Map<String, dynamic> toJSON() => {
        'id': id,
        'type': type.name,
        'url': url,
        'path': path,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ProductDocument.fromMap(Map<String, dynamic> map) => ProductDocument(
        id: map['id'] as String? ?? '',
        type: DocumentType.values.firstWhere((t) => t.name == map['type'],
            orElse: () => DocumentType.other),
        url: map['url'] as String? ?? '',
        path: map['path'] as String? ?? '',
        addedAt: Products.parseDate(map['addedAt']),
      );
}

/// One repair, service visit or maintenance task done on an appliance.
class ServiceRecord {
  DateTime date;
  String title;
  double? cost;
  String? provider;
  String? notes;

  ServiceRecord({
    required this.date,
    required this.title,
    this.cost,
    this.provider,
    this.notes,
  });

  Map<String, dynamic> toJSON() => {
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'title': title,
        'cost': cost,
        'provider': provider,
        'notes': notes,
      };

  factory ServiceRecord.fromMap(Map<String, dynamic> map) => ServiceRecord(
        date: Products.parseDate(map['date']),
        title: (map['title'] as String?)?.trim().isNotEmpty == true
            ? map['title']
            : 'Service',
        cost: (map['cost'] as num?)?.toDouble(),
        provider: Products._nonEmpty(map['provider']),
        notes: Products._nonEmpty(map['notes']),
      );
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
