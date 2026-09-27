import 'package:flutter/foundation.dart' hide Category;
import 'package:home_care/models/products.dart';
import 'package:home_care/services/firestore/firestore_services.dart';
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
  List<Products> get needsAttention => _products
      .where((p) => p.warrantyStatus != WarrantyStatus.active)
      .toList()
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

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
    return backup;
  }

  Future<void> restore(Products product) async {
    await FirestoreService.restoreProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Products? byId(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

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
