import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightsTab extends StatelessWidget {
  final VoidCallback onAdd;
  const InsightsTab({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final products = store.products;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ModernAppBar(
        title: 'Insights',
        subtitle: 'A snapshot of your home',
        actions: [
          AppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: store.refresh,
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: store.isLoading
                  ? const CircularProgressIndicator()
                  : EmptyState(
                      icon: Icons.insights_rounded,
                      title: 'Nothing to analyze yet',
                      message:
                          'Add a few appliances and your home insights will appear here.',
                      actionLabel: 'Add Appliance',
                      onAction: onAdd,
                    ),
            )
          : RefreshIndicator(
              onRefresh: store.refresh,
              edgeOffset: 100,
              child: ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 88, 20, 130),
                children: [
                  Entrance(child: _HealthCard(store: store)),
                  const SizedBox(height: 16),
                  Entrance(index: 1, child: _StatusRow(store: store)),
                  const SectionHeader(
                      title: 'By category',
                      padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                  Entrance(index: 2, child: _CategoryDonut(store: store)),
                  const SectionHeader(
                      title: 'Warranties ending — next 12 months',
                      padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                  Entrance(index: 3, child: _ExpiryBars(products: products)),
                  if (store.totalValue > 0) ...[
                    const SectionHeader(
                        title: 'Value by category',
                        padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                    Entrance(index: 4, child: _ValueBars(store: store)),
                  ],
                  if (products.any((p) =>
                      p.serviceHistory.isNotEmpty ||
                      p.nextServiceDate != null)) ...[
                    const SectionHeader(
                        title: 'Maintenance',
                        padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                    Entrance(index: 5, child: _Maintenance(store: store)),
                  ],
                  const SectionHeader(
                      title: 'Rooms',
                      padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                  Entrance(index: 5, child: _Rooms(products: products)),
                  const SectionHeader(
                      title: 'Fun facts',
                      padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
                  Entrance(index: 6, child: _Facts(products: products)),
                ],
              ),
            ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final ProductStore store;
  const _HealthCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final score = (store.coverage * 100).round();
    final (headline, detail) = switch (score) {
      >= 85 => ('Excellent protection', 'Almost everything is under warranty.'),
      >= 60 => ('Good protection', 'Most of your appliances are covered.'),
      >= 30 => ('Needs attention', 'Several warranties have lapsed.'),
      _ => ('Low protection', 'Consider extended warranties or service plans.'),
    };
    return DepthCard(
      gradient: AppColors.brandGradient,
      glow: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: store.coverage),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                painter: _GaugePainter(v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(v * 100).round()}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800)),
                      Text('score',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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
                Text('HOME HEALTH',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(headline,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(detail,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final ProductStore store;
  const _StatusRow({required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in WarrantyStatus.values) ...[
          if (s != WarrantyStatus.values.first) const SizedBox(width: 12),
          Expanded(
            child: DepthCard(
              depth: 0.6,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconOrb(icon: s.icon, color: s.color, size: 34),
                  const SizedBox(height: 10),
                  Text('${store.withStatus(s).length}',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.textMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  final ProductStore store;
  const _CategoryDonut({required this.store});

  @override
  Widget build(BuildContext context) {
    final entries = store.byCategory.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final total = store.count;

    return DepthCard(
      depth: 0.7,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _DonutPainter(
                  slices: [
                    for (final e in entries)
                      (e.value.length / total, ProductUtils.colorOf(e.key)),
                  ],
                  progress: t,
                  track: context.surfaceAlt,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                      Text('items',
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
              children: [
                for (final e in entries.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ProductUtils.colorOf(e.key),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ProductUtils.categoryName(e.key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Text('${e.value.length}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                if (entries.length > 6)
                  Text('+${entries.length - 6} more',
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryBars extends StatelessWidget {
  final List<Products> products;
  const _ExpiryBars({required this.products});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      for (var i = 0; i < 12; i++) DateTime(now.year, now.month + i, 1),
    ];
    final counts = [
      for (final m in months)
        products
            .where((p) =>
                p.warrantyPeriod.year == m.year &&
                p.warrantyPeriod.month == m.month &&
                !p.warrantyPeriod
                    .isBefore(DateTime(now.year, now.month, now.day)))
            .length,
    ];
    final maxCount = counts.fold<int>(0, math.max);
    final totalUpcoming = counts.fold<int>(0, (a, b) => a + b);

    return DepthCard(
      depth: 0.7,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalUpcoming == 0
                ? 'No warranties end in the next year'
                : '$totalUpcoming warrant${totalUpcoming == 1 ? 'y ends' : 'ies end'} within a year',
            style: TextStyle(color: context.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 12; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (counts[i] > 0)
                          Text('${counts[i]}',
                              style: const TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0,
                              end: maxCount == 0 ? 0 : counts[i] / maxCount),
                          duration: Duration(milliseconds: 600 + i * 50),
                          curve: Curves.easeOutBack,
                          builder: (context, v, _) => Container(
                            height: math.max(4, 88 * v),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              gradient: counts[i] > 0
                                  ? (i == 0
                                      ? AppColors.sunsetGradient
                                      : AppColors.brandGradient)
                                  : null,
                              color: counts[i] > 0 ? null : context.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: counts[i] > 0
                                  ? AppShadows.glow(AppColors.primary,
                                      strength: 0.4)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(DateFormat('MMM').format(months[i])[0],
                            style: TextStyle(
                                fontSize: 11,
                                color: context.textMuted,
                                fontWeight: FontWeight.w700)),
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
}

class _ValueBars extends StatelessWidget {
  final ProductStore store;
  const _ValueBars({required this.store});

  @override
  Widget build(BuildContext context) {
    final values = store.byCategory.map(
        (k, v) => MapEntry(k, v.fold<double>(0, (s, p) => s + (p.price ?? 0))));
    final entries = values.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.isEmpty ? 1.0 : entries.first.value;

    return DepthCard(
      depth: 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('Total',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
              const Spacer(),
              Text(ProductUtils.formatMoney(store.totalValue),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(ProductUtils.iconOf(e.key),
                      size: 18, color: ProductUtils.colorOf(e.key)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 96,
                    child: Text(ProductUtils.categoryName(e.key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(height: 10, color: context.surfaceAlt),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: e.value / maxV),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => FractionallySizedBox(
                              widthFactor: v,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: AppColors.shade(
                                      ProductUtils.colorOf(e.key)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 58,
                    child: Text(ProductUtils.formatMoney(e.value),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Rooms extends StatelessWidget {
  final List<Products> products;
  const _Rooms({required this.products});

  @override
  Widget build(BuildContext context) {
    final rooms = <String, int>{};
    for (final p in products) {
      final key = p.location.trim().isEmpty ? 'Unassigned' : p.location.trim();
      rooms[key] = (rooms[key] ?? 0) + 1;
    }
    final entries = rooms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.accent,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < entries.length; i++)
          DepthCard(
            depth: 0.5,
            radius: 18,
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconOrb(
                    icon: Icons.meeting_room_rounded,
                    color: palette[i % palette.length],
                    size: 30),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entries[i].key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(
                        '${entries[i].value} item${entries[i].value == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 11.5, color: context.textMuted)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  final List<Products> products;
  const _Facts({required this.products});

  @override
  Widget build(BuildContext context) {
    final byAge = [...products]
      ..sort((a, b) => a.purchasedDate.compareTo(b.purchasedDate));
    final oldest = byAge.first;
    final newest = byAge.last;
    final avgMonths = products
            .map((p) => p.warrantyPeriod.difference(p.purchasedDate).inDays)
            .fold<int>(0, (a, b) => a + b) /
        products.length /
        30.4;

    final withReceipt = products.where((p) => p.hasReceipt).length;
    final facts = [
      (
        Icons.receipt_long_rounded,
        'Receipts saved',
        '$withReceipt of ${products.length} appliances',
        withReceipt == products.length
            ? 'Every appliance has proof of purchase'
            : 'Add the rest to make warranty claims easier',
        withReceipt == products.length ? AppColors.success : AppColors.warning
      ),
      (
        Icons.history_rounded,
        'Oldest appliance',
        oldest.name,
        '${oldest.ageLabel} old',
        AppColors.secondary
      ),
      (
        Icons.fiber_new_rounded,
        'Newest addition',
        newest.name,
        'Bought ${ProductUtils.formatDate(newest.purchasedDate)}',
        AppColors.success
      ),
      (
        Icons.timelapse_rounded,
        'Average warranty',
        avgMonths >= 12
            ? '${(avgMonths / 12).toStringAsFixed(1)} years'
            : '${avgMonths.round()} months',
        'Across ${products.length} appliances',
        AppColors.info
      ),
    ];

    return Column(
      children: [
        for (final f in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DepthCard(
              depth: 0.6,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconOrb(icon: f.$1, color: f.$5, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2,
                            style: TextStyle(
                                fontSize: 12, color: context.textMuted)),
                        Text(f.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w800)),
                        Text(f.$4,
                            style: TextStyle(
                                fontSize: 12, color: context.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi * 0.75;
    const sweepAll = math.pi * 1.5;

    canvas.drawArc(
      rect,
      start,
      sweepAll,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      start,
      sweepAll * value,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

/// Donut with a subtle extruded look: each slice is drawn twice, a darker
/// copy offset downward and the lit face on top.
class _DonutPainter extends CustomPainter {
  final List<(double, Color)> slices;
  final double progress;
  final Color track;

  _DonutPainter(
      {required this.slices, required this.progress, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);

    const gap = 0.04;
    var start = -math.pi / 2;
    final totalSweep = 2 * math.pi * progress;
    for (final (fraction, color) in slices) {
      final sweep = totalSweep * fraction;
      final visible = slices.length > 1 ? math.max(0.0, sweep - gap) : sweep;
      if (visible > 0) {
        canvas.drawArc(
          rect.shift(const Offset(0, 4)),
          start,
          visible,
          false,
          Paint()
            ..color = AppColors.darken(color, 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
        canvas.drawArc(
          rect,
          start,
          visible,
          false,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromColor(color)
                    .withLightness(
                        (HSLColor.fromColor(color).lightness + 0.1).clamp(0, 1))
                    .toColor(),
                color,
              ],
            ).createShader(rect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.slices != slices || old.track != track;
}

class _Maintenance extends StatelessWidget {
  final ProductStore store;
  const _Maintenance({required this.store});

  @override
  Widget build(BuildContext context) {
    final products = store.products;
    final records =
        products.fold<int>(0, (n, p) => n + p.serviceHistory.length);
    final mostServiced = products
        .where((p) => p.serviceHistory.isNotEmpty)
        .toList()
      ..sort(
          (a, b) => b.serviceHistory.length.compareTo(a.serviceHistory.length));
    final next = store.scheduledServices
        .where((p) => p.serviceStatus != ServiceStatus.overdue)
        .firstOrNull;
    final overdue =
        products.where((p) => p.serviceStatus == ServiceStatus.overdue).length;

    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              Text(label,
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
            ],
          ),
        );

    return DepthCard(
      depth: 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              stat(ProductUtils.formatMoney(store.maintenanceCost),
                  'Spent on upkeep', AppColors.secondary),
              stat('$records', 'Service records', AppColors.info),
              stat('$overdue', 'Overdue',
                  overdue > 0 ? AppColors.danger : AppColors.success),
            ],
          ),
          if (mostServiced.isNotEmpty || next != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
          if (mostServiced.isNotEmpty)
            _line(
              context,
              Icons.handyman_rounded,
              'Most serviced',
              '${mostServiced.first.name} · ${mostServiced.first.serviceHistory.length}×',
            ),
          if (next != null)
            _line(context, Icons.event_repeat_rounded, 'Next service',
                '${next.name} · ${ProductUtils.formatDate(next.nextServiceDate!)}'),
        ],
      ),
    );
  }

  Widget _line(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label  ',
              style: TextStyle(color: context.textMuted, fontSize: 13)),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
