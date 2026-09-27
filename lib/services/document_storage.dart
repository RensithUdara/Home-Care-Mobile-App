import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:home_care/models/products.dart';

/// Uploads and removes appliance document photos in Firebase Storage.
///
/// Files live under `users/{uid}/products/{productId}/`, which the storage
/// security rules restrict to their owner.
class DocumentStorage {
  DocumentStorage._();

  static FirebaseStorage get _storage => FirebaseStorage.instance;

  static Future<ProductDocument> upload({
    required String uid,
    required String productId,
    required File file,
    required DocumentType type,
    void Function(double progress)? onProgress,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final path = 'users/$uid/products/$productId/$id.jpg';
    final ref = _storage.ref(path);

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg', customMetadata: {
        'type': type.name,
      }),
    );
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }

    return ProductDocument(
      id: id,
      type: type,
      url: await ref.getDownloadURL(),
      path: path,
      addedAt: DateTime.now(),
    );
  }

  /// Downloads a document's bytes (for sharing). Capped at 15 MB.
  static Future<Uint8List?> download(ProductDocument doc) =>
      _storage.ref(doc.path).getData(15 * 1024 * 1024);

  static Future<void> delete(ProductDocument doc) async {
    try {
      await _storage.ref(doc.path).delete();
    } on FirebaseException catch (e) {
      // Already gone is fine; anything else is worth surfacing.
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Best-effort removal of every file attached to [products].
  static Future<void> deleteAll(Iterable<Products> products) async {
    for (final p in products) {
      for (final d in p.documents) {
        try {
          await delete(d);
        } catch (e) {
          debugPrint('Could not delete ${d.path}: $e');
        }
      }
    }
  }
}
