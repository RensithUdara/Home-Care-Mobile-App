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
