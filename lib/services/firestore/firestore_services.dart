import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/products.dart';

class FirestoreService {
  static CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  static Future<void> addProduct(Products product) async {
    DocumentReference docRef = await _products.add(product.toJSON());

    // Update the product with the document ID
    product.id = docRef.id;

    await docRef.update({'id': product.id});
  }

  static Future<List<Products>> fetchProducts(String uid) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await _products.where('uid', isEqualTo: uid).get();

    return querySnapshot.docs.map((doc) {
      return Products.fromMap(doc.data(), doc.id);
    }).toList();
  }

  static Future<List<Products>> fetchProductsForHouseholds({
    required String uid,
    required List<String> householdIds,
  }) async {
    final byId = <String, Products>{};

    final legacy = await _products.where('uid', isEqualTo: uid).get();
    for (final doc in legacy.docs) {
      byId[doc.id] = Products.fromMap(doc.data(), doc.id);
    }

    for (var i = 0; i < householdIds.length; i += 10) {
      final end = i + 10 > householdIds.length ? householdIds.length : i + 10;
      final chunk = householdIds.sublist(i, end);
      if (chunk.isEmpty) continue;
      final shared = await _products.where('householdId', whereIn: chunk).get();
      for (final doc in shared.docs) {
        byId[doc.id] = Products.fromMap(doc.data(), doc.id);
      }
    }

    final products = byId.values.toList()
      ..sort((a, b) => b.purchasedDate.compareTo(a.purchasedDate));
    return products;
  }

  static Future<void> assignHouseholdToLegacyProducts({
    required String uid,
    required String householdId,
  }) async {
    final legacy = await _products.where('uid', isEqualTo: uid).get();
    final batch = FirebaseFirestore.instance.batch();
    var updates = 0;
    for (final doc in legacy.docs) {
      final data = doc.data();
      final existing = data['householdId'];
      if (existing is String && existing.trim().isNotEmpty) continue;
      batch.update(doc.reference, {'householdId': householdId});
      updates++;
    }
    if (updates > 0) await batch.commit();
  }

  static Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  /// Re-creates a deleted product under its original id (used by "Undo").
  static Future<void> restoreProduct(Products product) async {
    await _products.doc(product.id).set(product.toJSON());
  }

  static Future<void> editProduct(Products product) async {
    await _products.doc(product.id).update(product.toJSON());
  }

  static Future<void> submitFeedback(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('feedback').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
