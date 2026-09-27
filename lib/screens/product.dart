import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:home_care/components/product_form_sheet.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatefulWidget {
  final String productId;
  const ProductPage({super.key, required this.productId});

  /// Pushes the detail page, carrying the [ProductStore] across the route.
  static Future<void> open(BuildContext context, Products product) {
    final store = context.read<ProductStore>();
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: ProductPage(productId: product.id),
      ),
    ));
  }

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Drag rotation of the 3D showcase, in radians.
  double _rotY = -0.35;
  double _rotX = 0.12;
  bool _deleting = false;

  Future<void> _callSupport(String phoneNumber) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Could not make call: $e');
    }
  }

  Future<void> _delete(Products product) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete appliance?',
      message: 'Are you sure you want to delete "${product.name}"? '
          'This can\'t be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_forever_rounded,
    );
    if (!ok || !mounted) return;
    final store = context.read<ProductStore>();
    final navigator = Navigator.of(context);
    setState(() => _deleting = true);
    try {
      await store.delete(product);
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        AppSnack.error(context, 'Could not delete ${product.name}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final product = store.byId(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: const ModernAppBar(title: 'Appliance', showBack: true),
        body: _deleting
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.inventory_2_rounded,
                title: 'Not found',
                message: 'This appliance no longer exists.',
              ),
      );
    }

    final color = ProductUtils.colorOf(product.type);
    final status = product.warrantyStatus;
    final contact = product.contactNumber.toString();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 380,
            backgroundColor: AppColors.darken(color, 0.12),
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: AppBarIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back',
                  onGradient: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
            actions: [
              AppBarIconButton(
                icon: Icons.edit_rounded,
                tooltip: 'Edit',
                onGradient: true,
                onPressed: () => ProductFormSheet.show(context,
                    uid: store.uid, product: product, onSaved: store.refresh),
              ),
              const SizedBox(width: 10),
              AppBarIconButton(
                icon: Icons.delete_rounded,
                tooltip: 'Delete',
                onGradient: true,
                onPressed: () => _delete(product),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildShowcase(product, color),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Column(
                children: [
                  Entrance(child: _buildWarrantyCard(product, status)),
                  const SizedBox(height: 16),
                  Entrance(index: 1, child: _buildInfoGrid(product, contact)),
                  if (product.notes != null) ...[
                    const SizedBox(height: 16),
                    Entrance(index: 2, child: _buildNotes(product.notes!)),
                  ],
                  const SizedBox(height: 20),
                  Entrance(
                    index: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Button3D(
                            label: 'Call Support',
                            icon: Icons.phone_in_talk_rounded,
                            gradient: AppColors.shade(color),
                            onPressed: () => _callSupport(contact),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _secondaryAction(
                                  Icons.copy_rounded,
                                  'Copy number',
                                  () {
                                    Clipboard.setData(
                                        ClipboardData(text: contact));
                                    AppSnack.success(
                                        context, 'Support number copied');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _secondaryAction(
                                  Icons.ios_share_rounded,
                                  'Copy details',
                                  () {
                                    Clipboard.setData(ClipboardData(
                                        text: ProductUtils.shareText(product)));
                                    AppSnack.success(
                                        context, 'Details copied to clipboard');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcase(Products product, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromColor(color).withLightness(0.55).toColor(),
            AppColors.darken(color, 0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: FloatingOrbs()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _rotY = (_rotY + d.delta.dx * 0.012).clamp(-0.9, 0.9);
                      _rotX = (_rotX - d.delta.dy * 0.012).clamp(-0.5, 0.5);
                    }),
                    onPanEnd: (_) => setState(() {
                      _rotY = -0.35;
                      _rotX = 0.12;
                    }),
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween(end: Offset(_rotX, _rotY)),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      builder: (context, r, _) => _Pedestal(
                        product: product,
                        color: color,
                        rotX: r.dx,
                        rotY: r.dy,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 44),
                  child: Column(
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _glassTag(ProductUtils.iconOf(product.type),
                              ProductUtils.categoryName(product.type)),
                          if (product.brand != null)
                            _glassTag(Icons.workspace_premium_rounded,
                                product.brand!),
                          _glassTag(Icons.place_rounded, product.location),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWarrantyCard(Products product, WarrantyStatus status) {
    final remaining = 1 - product.warrantyElapsed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DepthCard(
        glow: status.color,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: remaining),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CustomPaint(
                  painter: _RingPainter(
                    value: v,
                    color: status.color,
                    track: context.surfaceAlt,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(v * 100).round()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: status.color,
                          ),
                        ),
                        Text('left',
                            style: TextStyle(
                                fontSize: 11, color: context.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(status: status),
                  const SizedBox(height: 10),
                  Text(
                    product.daysLeftLabel,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == WarrantyStatus.expired
                        ? 'Ended ${ProductUtils.formatDate(product.warrantyPeriod)}'
                        : 'Covered until ${ProductUtils.formatDate(product.warrantyPeriod)}',
                    style: TextStyle(color: context.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Products product, String contact) {
    final tiles = <(IconData, String, String, Color)>[
      (
        Icons.shopping_bag_rounded,
        'Purchased',
        ProductUtils.formatDate(product.purchasedDate),
        AppColors.info
      ),
      (
        Icons.hourglass_bottom_rounded,
        'Age',
        product.ageLabel,
        AppColors.secondary
      ),
      (Icons.support_agent_rounded, 'Support', contact, AppColors.warning),
      (
        Icons.payments_rounded,
        'Price',
        product.price == null ? '—' : ProductUtils.formatMoney(product.price!),
        AppColors.success
      ),
      if (product.serialNumber != null)
        (
          Icons.qr_code_2_rounded,
          'Serial no.',
          product.serialNumber!,
          AppColors.accent
        ),
      (
        Icons.tag_rounded,
        'Product ID',
        product.id.length >= 8
            ? product.id.substring(0, 8).toUpperCase()
            : product.id.toUpperCase(),
        const Color(0xFF64748B)
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.75,
        children: [
          for (final t in tiles)
            DepthCard(
              depth: 0.6,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconOrb(icon: t.$1, color: t.$4, size: 30),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.$2,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textMuted,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  Text(
                    t.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotes(String notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DepthCard(
        depth: 0.6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconOrb(
                icon: Icons.sticky_note_2_rounded,
                color: AppColors.warning,
                size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(notes,
                      style: TextStyle(color: context.textMuted, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryAction(IconData icon, String label, VoidCallback onTap) {
    return DepthCard(
      onTap: onTap,
      depth: 0.5,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// The product image floating above a lit pedestal, rotated in 3D.
class _Pedestal extends StatelessWidget {
  final Products product;
  final Color color;
  final double rotX;
  final double rotY;

  const _Pedestal({
    required this.product,
    required this.color,
    required this.rotX,
    required this.rotY,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Floor shadow shifts opposite to the tilt.
          Positioned(
            bottom: 0,
            child: Transform.translate(
              offset: Offset(-rotY * 30, 0),
              child: Container(
                width: 150,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateX(rotX)
                ..rotateY(rotY),
              child: Hero(
                tag: 'product_${product.id}',
                child: Container(
                  width: 158,
                  height: 158,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    gradient: LinearGradient(
                      begin: Alignment(-math.sin(rotY) - 0.6, -0.8),
                      end: Alignment(math.sin(rotY) + 0.6, 0.9),
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.82),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darken(color, 0.25)
                            .withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: Offset(-rotY * 24, 26),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    ProductUtils.getImagePath(
                        ProductUtils.typeKey(product.type)),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                        ProductUtils.iconOf(product.type),
                        size: 80,
                        color: color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _RingPainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (value <= 0) return;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * value;
    canvas.drawArc(
      arcRect.shift(const Offset(0, 3)),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi,
          transform: const GradientRotation(-math.pi / 2),
          colors: [
            HSLColor.fromColor(color).withLightness(0.62).toColor(),
            color,
          ],
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
