import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/services/document_storage.dart';
import 'package:home_care/services/inventory_report.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

/// Preview, print and share a PDF inventory of every appliance.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  static Future<void> open(BuildContext context) {
    final store = context.read<ProductStore>();
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: const ReportPage(),
      ),
    ));
  }

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportOptions _options = const ReportOptions();
  final Map<String, Uint8List> _photos = {};
  bool _loadingPhotos = false;
  bool _photosLoaded = false;
  int _failedPhotos = 0;

  @override
  void initState() {
    super.initState();
    if (_options.includePhotos) _loadPhotos();
  }

  /// Downloads up to four photos per appliance, once.
  Future<void> _loadPhotos() async {
    if (_photosLoaded || _loadingPhotos) return;
    final docs = context
        .read<ProductStore>()
        .products
        .expand((p) => p.documents.take(4))
        .toList();
    if (docs.isEmpty) {
      _photosLoaded = true;
      return;
    }
    setState(() => _loadingPhotos = true);
    var failed = 0;
    await Future.wait(docs.map((d) async {
      try {
        final bytes = await DocumentStorage.download(d);
        if (bytes != null) _photos[d.id] = bytes;
      } catch (_) {
        failed++;
      }
    }));
    if (!mounted) return;
    setState(() {
      _loadingPhotos = false;
      _photosLoaded = true;
      _failedPhotos = failed;
    });
    if (failed > 0) {
      AppSnack.info(context,
          '$failed photo${failed == 1 ? '' : 's'} could not be downloaded and will be left out');
    }
  }

  void _toggle(ReportOptions next) {
    HapticFeedback.selectionClick();
    setState(() => _options = next);
    if (next.includePhotos) _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final user = FirebaseAuth.instance.currentUser;
    final fileName =
        'home-inventory-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
    final waiting = _options.includePhotos && _loadingPhotos;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Inventory Report',
        subtitle: '${store.count} appliances · PDF',
        showBack: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              children: [
                _OptionChip(
                  icon: Icons.meeting_room_rounded,
                  label: 'Group by room',
                  selected: _options.groupByRoom,
                  onTap: () => _toggle(_options.copyWith(
                      groupByRoom: !_options.groupByRoom)),
                ),
                _OptionChip(
                  icon: Icons.build_rounded,
                  label: 'Service history',
                  selected: _options.includeServiceHistory,
                  onTap: () => _toggle(_options.copyWith(
                      includeServiceHistory: !_options.includeServiceHistory)),
                ),
                _OptionChip(
                  icon: Icons.photo_rounded,
                  label: 'Photos',
                  selected: _options.includePhotos,
                  onTap: () => _toggle(_options.copyWith(
                      includePhotos: !_options.includePhotos)),
                ),
              ],
            ),
          ),
          Expanded(
            child: waiting
                ? const _Preparing()
                : PdfPreview(
                    // Rebuild the document whenever an option changes.
                    key: ValueKey(
                        '${_options.groupByRoom}${_options.includeServiceHistory}'
                        '${_options.includePhotos}${_photos.length}$_failedPhotos'),
                    build: (format) => buildInventoryReport(
                      products: store.products,
                      ownerName: user?.displayName ?? '',
                      ownerEmail: user?.email ?? '',
                      options: _options,
                      photos: _options.includePhotos ? _photos : const {},
                      format: format,
                    ),
                    pdfFileName: fileName,
                    canDebug: false,
                    canChangeOrientation: false,
                    shareActionExtraSubject: 'Home inventory report',
                    scrollViewDecoration:
                        BoxDecoration(color: context.surfaceAlt),
                    loadingWidget: const _Preparing(),
                    onError: (context, error) => EmptyState(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'Could not create the report',
                      message: '$error',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? Colors.transparent : context.outline),
            boxShadow: selected
                ? AppShadows.glow(AppColors.primary, strength: 0.6)
                : null,
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.check_rounded : icon,
                  size: 17,
                  color: selected ? Colors.white : context.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : context.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Preparing your report…',
              style: TextStyle(
                  color: context.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
