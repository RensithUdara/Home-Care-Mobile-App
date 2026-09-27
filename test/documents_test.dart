import 'package:flutter_test/flutter_test.dart';
import 'package:home_care/models/products.dart';

Products _p({List<ProductDocument>? docs}) => Products(
      uid: 'u',
      id: 'p1',
      name: 'TV',
      location: 'Lounge',
      purchasedDate: DateTime(2024, 1, 1),
      warrantyPeriod: DateTime(2026, 1, 1),
      contactNumber: 1,
      type: Category.Television,
      documents: docs,
    );

ProductDocument _doc(String id, DocumentType type, DateTime added) =>
    ProductDocument(
      id: id,
      type: type,
      url: 'https://example.com/$id.jpg',
      path: 'users/u/products/p1/$id.jpg',
      addedAt: added,
    );

void main() {
  test('documents round-trip through Firestore JSON, newest first', () {
    final p = _p(docs: [
      _doc('a', DocumentType.manual, DateTime(2024, 1, 1)),
      _doc('b', DocumentType.receipt, DateTime(2025, 6, 1)),
    ]);
    final copy = Products.fromMap(p.toJSON(), p.id);
    expect(copy.documents.map((d) => d.id), ['b', 'a']);
    expect(copy.documents.first.type, DocumentType.receipt);
    expect(copy.documents.first.path, 'users/u/products/p1/b.jpg');
  });

  test('hasReceipt counts receipts and invoices only', () {
    expect(_p().hasReceipt, isFalse);
    expect(
        _p(docs: [_doc('m', DocumentType.manual, DateTime(2024))]).hasReceipt,
        isFalse);
    expect(
        _p(docs: [_doc('i', DocumentType.invoice, DateTime(2024))]).hasReceipt,
        isTrue);
  });

  test('ignores malformed entries and unknown types', () {
    final p = Products.fromMap({
      'purchasedDate': '2024-01-01',
      'warrantyPeriod': '2025-01-01',
      'type': 'Fan',
      'documents': [
        {'id': 'x', 'type': 'hologram', 'url': 'https://e.com/x', 'path': 'p'},
        {'id': 'no-url', 'type': 'receipt'},
        'not a map',
      ],
    }, 'id');
    expect(p.documents.length, 1);
    expect(p.documents.single.type, DocumentType.other);
  });

  test('legacy products have no documents', () {
    final p = Products.fromMap({
      'purchasedDate': '2024-01-01',
      'warrantyPeriod': '2025-01-01',
      'type': 'Fan',
    }, 'id');
    expect(p.documents, isEmpty);
  });
}
