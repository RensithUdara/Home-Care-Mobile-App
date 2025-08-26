import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/products.dart';

class FirestoreService {
  static Future<void> addProduct(Products product) async {
    CollectionReference products =
        FirebaseFirestore.instance.collection('products');
    DocumentReference docRef = await products.add(product.toJSON());

    // Update the product with the document ID
    product.id = docRef.id;

    await docRef.update({'id': product.id});
  }

  static Future<List<Products>> fetchProducts(String uid) async {
    CollectionReference productsCollection =
        FirebaseFirestore.instance.collection('products');
    QuerySnapshot querySnapshot =
        await productsCollection.where('uid', isEqualTo: uid).get();

    return querySnapshot.docs.map((doc) {
      return Products.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  static Future<void> deleteProduct(String id) async {
    CollectionReference productsCollection =
        FirebaseFirestore.instance.collection('products');
    await productsCollection.doc(id).delete();
  }

  static Future<void> editProduct(Products product) async {
    CollectionReference productsCollection =
        FirebaseFirestore.instance.collection('products');
    await productsCollection.doc(product.id).update(product.toJSON());
  }
}
