import 'package:flutter/foundation.dart' hide Category;
import 'package:home_care/models/products.dart';
import 'package:home_care/services/document_storage.dart';
import 'package:home_care/services/firestore/firestore_services.dart';
import 'package:home_care/services/reminder_service.dart';
import 'package:home_care/utils/warranty.dart';

enum ProductSort { recent, name, expiry, price }

extension ProductSortX on ProductSort {
  String get label => switch (this) {
        ProductSort.recent => 'Recently purchased',
        ProductSort.name => 'Name (A–Z)',
        ProductSort.expiry => 'Warranty ending first',
        ProductSort.price => 'Price (high to low)',
      };
}

/// Single source of truth for the signed-in user's appliances, shared by the
/// Home, Insights, Warranty and Profile tabs so they never drift apart.
class ProductStore extends ChangeNotifier {
  final String uid;

  ProductStore(this.uid) {
    refresh();
  }

  List<Products> _products = [];
  bool _loading = true;
  String? _error;

  List<Products> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  String? get error => _error;

  int get count => _products.length;

  List<Products> withStatus(WarrantyStatus status) =>
      _products.where((p) => p.warrantyStatus == status).toList();

  /// Expired or expiring soon — what the notification badge counts.
  List<Products> get needsAttention =>
      _products.where((p) => p.warrantyStatus != WarrantyStatus.active).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  /// Appliances whose service is overdue or due within a week.
  List<Products> get serviceAlerts => _products.where(isServiceAlert).toList()
    ..sort((a, b) => a.serviceDaysLeft!.compareTo(b.serviceDaysLeft!));

  /// Appliances with a next service date, soonest first.
  List<Products> get scheduledServices =>
      _products.where((p) => p.nextServiceDate != null).toList()
        ..sort((a, b) => a.nextServiceDate!.compareTo(b.nextServiceDate!));

  /// Distinct products needing attention for warranty or service reasons.
  int get alertCount => {
        ...needsAttention.map((p) => p.id),
        ...serviceAlerts.map((p) => p.id)
      }.length;

  List<Products> get favorites => _products.where((p) => p.isFavorite).toList();

  double get maintenanceCost =>
      _products.fold(0.0, (sum, p) => sum + p.maintenanceCost);

  double get totalValue =>
      _products.fold(0.0, (sum, p) => sum + (p.price ?? 0));

  /// Share of appliances still under warranty, 0..1.
  double get coverage {
    if (_products.isEmpty) return 0;
    final covered =
        _products.where((p) => p.warrantyStatus != WarrantyStatus.expired);
    return covered.length / _products.length;
  }

  Map<Category, List<Products>> get byCategory {
    final map = <Category, List<Products>>{};
    for (final p in _products) {
      map.putIfAbsent(p.type, () => []).add(p);
    }
    return map;
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await FirestoreService.fetchProducts(uid);
    } catch (e) {
      _error = 'Could not load your appliances. Pull down to retry.';
    }
    _loading = false;
    notifyListeners();
    _syncReminders();
  }

  void _syncReminders() => ReminderService.instance.sync(_products);

  /// Saves [updated] (matched by id), applying it locally first so the UI
  /// responds instantly, and rolls back if the write fails.
  Future<void> update(Products updated) async {
    final i = _products.indexWhere((p) => p.id == updated.id);
    if (i < 0) return;
    final previous = _products[i];
    _products[i] = updated;
    notifyListeners();
    try {
      await FirestoreService.editProduct(updated);
      _syncReminders();
    } catch (e) {
      _products[i] = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFavorite(Products product) {
    final updated = product.copy()..isFavorite = !product.isFavorite;
    return update(updated);
  }

  /// Removes the product locally right away, then deletes it remotely.
  /// Returns a copy that can be passed to [restore] for undo.
  Future<Products> delete(Products product) async {
    final backup = product.copy();
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();
    try {
      await FirestoreService.deleteProduct(product.id);
    } catch (e) {
      _products.add(backup);
      notifyListeners();
      rethrow;
    }
    _syncReminders();
    return backup;
  }

  /// Deletes a product's stored photos. Call once undo is no longer
  /// possible, since a restored product would point at missing files.
  Future<void> purgeFiles(Products product) =>
      DocumentStorage.deleteAll([product]);

  /// Appliances without a receipt or invoice photo.
  List<Products> get missingReceipts =>
      _products.where((p) => !p.hasReceipt).toList();

  Future<void> restore(Products product) async {
    await FirestoreService.restoreProduct(product);
    _products.add(product);
    notifyListeners();
    _syncReminders();
  }

  Products? byId(String id) => _products.where((p) => p.id == id).firstOrNull;

  static List<Products> sorted(List<Products> list, ProductSort sort) {
    final copy = [...list];
    switch (sort) {
      case ProductSort.recent:
        copy.sort((a, b) => b.purchasedDate.compareTo(a.purchasedDate));
      case ProductSort.name:
        copy.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProductSort.expiry:
        copy.sort((a, b) => a.warrantyPeriod.compareTo(b.warrantyPeriod));
      case ProductSort.price:
        copy.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }
    return copy;
  }
}

String _normalizeSerial(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Finds the product whose serial number matches a scanned value. Ignores
/// case, spaces and punctuation, and also matches when the scan contains the
/// serial (e.g. a QR code reading "SN: ABC123 / MODEL X").
Products? findBySerial(List<Products> products, String scanned) {
  final scan = _normalizeSerial(scanned);
  if (scan.isEmpty) return null;
  Products? partial;
  for (final p in products) {
    final serial = _normalizeSerial(p.serialNumber ?? '');
    if (serial.isEmpty) continue;
    if (serial == scan) return p;
    if (serial.length >= 5 && scan.contains(serial)) partial ??= p;
  }
  return partial;
}
