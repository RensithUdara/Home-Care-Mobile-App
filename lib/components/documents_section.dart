import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/document_storage.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

IconData documentIcon(DocumentType type) => switch (type) {
      DocumentType.receipt => Icons.receipt_long_rounded,
      DocumentType.warrantyCard => Icons.verified_rounded,
      DocumentType.invoice => Icons.request_quote_rounded,
      DocumentType.manual => Icons.menu_book_rounded,
      DocumentType.photo => Icons.photo_camera_rounded,
      DocumentType.other => Icons.description_rounded,
    };

Color documentColor(DocumentType type) => switch (type) {
      DocumentType.receipt => AppColors.success,
      DocumentType.warrantyCard => AppColors.primary,
      DocumentType.invoice => AppColors.info,
      DocumentType.manual => AppColors.secondary,
      DocumentType.photo => AppColors.warning,
      DocumentType.other => const Color(0xFF64748B),
    };

/// Horizontal gallery of receipt / warranty card / manual photos.
class DocumentsSection extends StatefulWidget {
  final Products product;
  const DocumentsSection({super.key, required this.product});

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  double? _progress; // non-null while uploading

  Future<void> _add() async {
    final picked = await showModalBottomSheet<(DocumentType, ImageSource)>(
      context: context,
      builder: (_) => const _AddDocumentSheet(),
    );
    if (picked == null || !mounted) return;
    final (type, source) = picked;

    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        AppSnack.error(
            context,
            e.code.contains('denied')
                ? 'Camera or photo access was denied. Enable it in your phone settings.'
                : 'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}');
      }
      return;
    }
    if (image == null || !mounted) return;

    final store = context.read<ProductStore>();
    setState(() => _progress = 0);
    try {
      final doc = await DocumentStorage.upload(
        uid: store.uid,
        productId: widget.product.id,
        file: File(image.path),
        type: type,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      // Re-read the latest product so concurrent edits aren't lost.
      final latest = store.byId(widget.product.id) ?? widget.product;
      await store.update(latest.copy()..documents.insert(0, doc));
      if (mounted) AppSnack.success(context, '${type.label} saved');
    } catch (e) {
      if (mounted) {
        AppSnack.error(context,
            'Upload failed. Check your connection and that Firebase Storage is enabled.');
      }
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  void _open(int index) {
    final store = context.read<ProductStore>();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: DocumentViewer(
          productId: widget.product.id,
          initialIndex: index,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.product.documents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Receipts & documents',
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            trailing: docs.isEmpty ? null : '${docs.length}',
          ),
          if (docs.isEmpty && _progress == null)
            DepthCard(
              onTap: _add,
              tilt: false,
              depth: 0.6,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const IconOrb(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.success,
                      size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add receipt or warranty card',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Proof of purchase makes warranty claims easy',
                            style: TextStyle(
                                fontSize: 12.5, color: context.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.add_a_photo_rounded,
                      color: AppColors.primary),
                ],
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _AddTile(onTap: _progress == null ? _add : null),
                  if (_progress != null) _UploadingTile(progress: _progress!),
                  for (var i = 0; i < docs.length; i++)
                    _Thumb(doc: docs[i], onTap: () => _open(i)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddTile({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 104,
        child: DepthCard(
          onTap: onTap,
          tilt: false,
          depth: 0.5,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IconOrb(
                  icon: Icons.add_a_photo_rounded,
                  color: AppColors.primary,
                  size: 42),
              const SizedBox(height: 10),
              Text('Add',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: onTap == null ? context.textMuted : null)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  final double progress;
  const _UploadingTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 110,
        child: DepthCard(
          depth: 0.5,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null, strokeWidth: 4),
              ),
              const SizedBox(height: 12),
              Text('${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Uploading',
                  style: TextStyle(fontSize: 11.5, color: context.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final ProductDocument doc;
  final VoidCallback onTap;
  const _Thumb({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = documentColor(doc.type);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 110,
        child: DepthCard(
          onTap: onTap,
          depth: 0.6,
          padding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'doc_${doc.id}',
                child: Image.network(
                  doc.url,
                  fit: BoxFit.cover,
                  cacheWidth: 330,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Center(
                          child: Icon(documentIcon(doc.type),
                              color: color.withValues(alpha: 0.5), size: 32)),
                  errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: context.textMuted)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(documentIcon(doc.type),
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(doc.type.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet();

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  DocumentType _type = DocumentType.receipt;

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Add document',
      subtitle: 'What are you adding?',
      icon: Icons.add_a_photo_rounded,
      color: AppColors.success,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in DocumentType.values)
                  ChoiceChip(
                    avatar: Icon(documentIcon(t),
                        size: 18,
                        color: _type == t ? Colors.white : documentColor(t)),
                    label: Text(t.label),
                    selected: _type == t,
                    selectedColor: documentColor(t),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _type == t ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _type = t);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Button3D(
                    label: 'Camera',
                    icon: Icons.photo_camera_rounded,
                    height: 50,
                    onPressed: () =>
                        Navigator.pop(context, (_type, ImageSource.camera)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Button3D(
                    label: 'Gallery',
                    icon: Icons.photo_library_rounded,
                    height: 50,
                    gradient: AppColors.oceanGradient,
                    onPressed: () =>
                        Navigator.pop(context, (_type, ImageSource.gallery)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable viewer with share and delete.
class DocumentViewer extends StatefulWidget {
  final String productId;
  final int initialIndex;
  const DocumentViewer(
      {super.key, required this.productId, required this.initialIndex});

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share(
      Products product, ProductDocument doc, BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() => _busy = true);
    try {
      final bytes = await DocumentStorage.download(doc);
      if (bytes == null) throw Exception('empty');
      final name = '${product.name}-${doc.type.label}'
          .replaceAll(RegExp(r'[^\w-]+'), '_');
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/jpeg')],
        fileNameOverrides: ['$name.jpg'],
        text: '${doc.type.label} for ${product.name}',
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not share this document');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Products product, ProductDocument doc) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${doc.type.label.toLowerCase()}?',
      message: 'This photo will be permanently removed.',
      confirmLabel: 'Delete',
      icon: Icons.delete_rounded,
    );
    if (!ok || !mounted) return;
    final store = context.read<ProductStore>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await store
          .update(product.copy()..documents.removeWhere((d) => d.id == doc.id));
      await DocumentStorage.delete(doc);
      if (product.documents.length <= 1) {
        navigator.pop();
      } else if (mounted) {
        setState(() => _index = _index.clamp(0, product.documents.length - 2));
      }
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not delete this document');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductStore>().byId(widget.productId);
    final docs = product?.documents ?? const <ProductDocument>[];
    if (product == null || docs.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final index = _index.clamp(0, docs.length - 1);
    final doc = docs[index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.type.label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              Text(
                'Added ${DateFormat.yMMMd().format(doc.addedAt)}'
                '${docs.length > 1 ? ' · ${index + 1} of ${docs.length}' : ''}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
          actions: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
              )
            else ...[
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => _share(product, doc, buttonContext),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(product, doc),
              ),
            ],
          ],
        ),
        body: PageView.builder(
          controller: _pages,
          itemCount: docs.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Hero(
                tag: 'doc_${docs[i].id}',
                child: Image.network(
                  docs[i].url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
