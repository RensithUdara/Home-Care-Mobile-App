import 'dart:typed_data';

import 'package:flutter/foundation.dart' hide Category;
import 'package:home_care/models/products.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportOptions {
  final bool groupByRoom;
  final bool includeServiceHistory;
  final bool includePhotos;

  const ReportOptions({
    this.groupByRoom = true,
    this.includeServiceHistory = true,
    this.includePhotos = true,
  });

  ReportOptions copyWith({
    bool? groupByRoom,
    bool? includeServiceHistory,
    bool? includePhotos,
  }) =>
      ReportOptions(
        groupByRoom: groupByRoom ?? this.groupByRoom,
        includeServiceHistory:
            includeServiceHistory ?? this.includeServiceHistory,
        includePhotos: includePhotos ?? this.includePhotos,
      );
}

// Brand colors mirrored from the app theme.
const _primary = PdfColor.fromInt(0xFF5B5BF7);
const _secondary = PdfColor.fromInt(0xFF9B5CF6);
const _ink = PdfColor.fromInt(0xFF151837);
const _muted = PdfColor.fromInt(0xFF6B7094);
const _line = PdfColor.fromInt(0xFFDADDEF);
const _zebra = PdfColor.fromInt(0xFFF5F6FC);

PdfColor _statusColor(WarrantyStatus s) => switch (s) {
      WarrantyStatus.active => const PdfColor.fromInt(0xFF10B981),
      WarrantyStatus.expiringSoon => const PdfColor.fromInt(0xFFF59E0B),
      WarrantyStatus.expired => const PdfColor.fromInt(0xFFEF4444),
    };

/// Fonts with wide Unicode coverage, downloaded once per app session.
/// Falls back to the built-in Helvetica (Latin-1 only) when offline.
class _Fonts {
  final pw.Font? regular;
  final pw.Font? bold;
  const _Fonts(this.regular, this.bold);

  bool get unicode => regular != null;

  static _Fonts? _cached;

  static Future<_Fonts> load() async {
    if (_cached != null) return _cached!;
    try {
      final fonts = _Fonts(
        await PdfGoogleFonts.notoSansRegular(),
        await PdfGoogleFonts.notoSansBold(),
      );
      return _cached = fonts;
    } catch (e) {
      debugPrint('PDF fonts unavailable, using Helvetica: $e');
      return const _Fonts(null, null);
    }
  }
}

/// Builds a printable inventory of [products] as PDF bytes.
///
/// [photos] maps document id to image bytes; only documents present in the
/// map are drawn, so callers decide what to download.
Future<Uint8List> buildInventoryReport({
  required List<Products> products,
  required String ownerName,
  required String ownerEmail,
  required ReportOptions options,
  Map<String, Uint8List> photos = const {},
  PdfPageFormat format = PdfPageFormat.a4,
  DateTime? generatedAt,
}) async {
  final fonts = await _Fonts.load();
  final now = generatedAt ?? DateTime.now();
  final dateFmt = DateFormat('d MMM yyyy');

  // Helvetica can only draw Latin-1; replace anything else so generation
  // never fails on names in other scripts.
  String t(String s) => fonts.unicode
      ? s
      : s.replaceAll(RegExp(r'[^\x00-\xFF]'), '?');

  final sorted = [...products]..sort((a, b) {
      if (options.groupByRoom) {
        final r = a.location.toLowerCase().compareTo(b.location.toLowerCase());
        if (r != 0) return r;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  final totalValue = products.fold<double>(0, (s, p) => s + (p.price ?? 0));
  final upkeep = products.fold<double>(0, (s, p) => s + p.maintenanceCost);
  final covered =
      products.where((p) => p.warrantyStatus != WarrantyStatus.expired).length;
  final receipts = products.where((p) => p.hasReceipt).length;

  final doc = pw.Document(
    title: 'Home Inventory Report',
    author: ownerName,
    creator: 'Home Care',
    theme: fonts.unicode
        ? pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold)
        : null,
  );

  pw.Widget stat(String value, String label) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
          ]),
        ),
      );

  final header = pw.Container(
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      gradient: const pw.LinearGradient(
        colors: [_primary, _secondary],
        begin: pw.Alignment.topLeft,
        end: pw.Alignment.bottomRight,
      ),
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Home Inventory Report',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      t([ownerName, ownerEmail]
                          .where((s) => s.isNotEmpty)
                          .join('  |  ')),
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.white)),
                ],
              ),
            ),
            pw.Text('Generated ${dateFmt.format(now)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Row(children: [
          stat('${products.length}', 'Appliances'),
          stat(ProductUtils.formatMoney(totalValue), 'Total value'),
          stat(
              products.isEmpty
                  ? '-'
                  : '${(covered * 100 / products.length).round()}%',
              'Under warranty'),
          stat(ProductUtils.formatMoney(upkeep), 'Spent on upkeep'),
          stat('$receipts/${products.length}', 'Receipts saved'),
        ]),
      ],
    ),
  );

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Row(children: [
          pw.Container(
            width: 3,
            height: 14,
            decoration: pw.BoxDecoration(
                color: _primary, borderRadius: pw.BorderRadius.circular(2)),
          ),
          pw.SizedBox(width: 6),
          pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
        ]),
      );

  // ---- Summary table ----
  const headers = [
    'Appliance',
    'Category',
    'Room',
    'Serial no.',
    'Purchased',
    'Warranty until',
    'Status',
    'Price',
  ];
  final rows = [
    for (final p in sorted)
      [
        t(p.brand == null ? p.name : '${p.name}\n${p.brand}'),
        ProductUtils.categoryName(p.type),
        t(p.location),
        t(p.serialNumber ?? '-'),
        dateFmt.format(p.purchasedDate),
        dateFmt.format(p.warrantyPeriod),
        p.warrantyStatus.label,
        p.price == null ? '-' : ProductUtils.formatMoney(p.price!),
      ],
  ];

  final table = pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: null,
    headerStyle: pw.TextStyle(
        fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: const pw.BoxDecoration(color: _primary),
    cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
    oddRowDecoration: const pw.BoxDecoration(color: _zebra),
    columnWidths: {
      0: const pw.FlexColumnWidth(2.2),
      1: const pw.FlexColumnWidth(1.5),
      2: const pw.FlexColumnWidth(1.3),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(1.3),
      5: const pw.FlexColumnWidth(1.3),
      6: const pw.FlexColumnWidth(1.2),
      7: const pw.FlexColumnWidth(1),
    },
    cellAlignments: {7: pw.Alignment.centerRight},
    headerAlignments: {7: pw.Alignment.centerRight},
    cellDecoration: (index, data, rowNum) {
      // Tint the status cell with the warranty color.
      if (index != 6 || rowNum == 0) return const pw.BoxDecoration();
      final status = sorted[rowNum - 1].warrantyStatus;
      return pw.BoxDecoration(color: _statusColor(status).shade(0.1));
    },
  );

  // ---- Per-appliance details ----
  final details = <pw.Widget>[];
  for (final p in sorted) {
    final history = options.includeServiceHistory ? p.serviceHistory : const [];
    final images = options.includePhotos
        ? p.documents.where((d) => photos.containsKey(d.id)).take(4).toList()
        : const <ProductDocument>[];
    if (p.notes == null &&
        history.isEmpty &&
        images.isEmpty &&
        p.nextServiceDate == null) {
      continue;
    }

    details.add(pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Expanded(
              child: pw.Text(t(p.name),
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text(
                t('${ProductUtils.categoryName(p.type)}  |  ${p.location}'),
                style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          ]),
          pw.SizedBox(height: 4),
          pw.Text(
            t([
              'Support: ${p.contactNumber}',
              if (p.nextServiceDate != null)
                'Next service: ${dateFmt.format(p.nextServiceDate!)}',
              if (p.maintenanceCost > 0)
                'Upkeep: ${ProductUtils.formatMoney(p.maintenanceCost)}',
            ].join('   ')),
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
          if (p.notes != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(t(p.notes!), style: const pw.TextStyle(fontSize: 9)),
          ],
          if (history.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Service', 'By', 'Cost'],
              data: [
                for (final r in history)
                  [
                    dateFmt.format(r.date),
                    t(r.notes == null ? r.title : '${r.title} - ${r.notes}'),
                    t(r.provider ?? '-'),
                    r.cost == null ? '-' : ProductUtils.formatMoney(r.cost!),
                  ],
              ],
              border: null,
              headerStyle: pw.TextStyle(
                  fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _ink),
              headerDecoration: const pw.BoxDecoration(color: _zebra),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FixedColumnWidth(50),
              },
              cellAlignments: {3: pw.Alignment.centerRight},
            ),
          ],
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Row(children: [
              for (final d in images)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 8),
                  child: pw.Column(children: [
                    pw.Container(
                      width: 110,
                      height: 110,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _line),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Image(pw.MemoryImage(photos[d.id]!),
                          fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(d.type.label,
                        style: const pw.TextStyle(fontSize: 7, color: _muted)),
                  ]),
                ),
            ]),
          ],
        ],
      ),
    ));
  }

  doc.addPage(pw.MultiPage(
    pageFormat: format,
    margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
    footer: (context) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(children: [
        pw.Text('Home Care  |  Home Inventory Report',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
        pw.Spacer(),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
      ]),
    ),
    build: (context) => [
      header,
      if (products.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 40),
          child: pw.Center(
              child: pw.Text('No appliances added yet.',
                  style: const pw.TextStyle(color: _muted))),
        )
      else ...[
        sectionTitle('Appliances'),
        table,
        if (details.isNotEmpty) ...[
          sectionTitle('Details, service history & documents'),
          ...details,
        ],
      ],
    ],
  ));

  return doc.save();
}
