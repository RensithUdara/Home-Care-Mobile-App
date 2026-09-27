import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/components/ui/modern_app_bar.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/screens/product.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Timeline of every warranty, soonest-ending first, filterable by status.
class WarrantyTab extends StatefulWidget {
  final VoidCallback onAdd;
  const WarrantyTab({super.key, required this.onAdd});

  @override
  State<WarrantyTab> createState() => _WarrantyTabState();
}

class _WarrantyTabState extends State<WarrantyTab> {
  WarrantyStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProductStore>();
    final all = store.products;

    // Expiring first, then active by date, expired last (most recent first).
    int rank(Products p) => switch (p.warrantyStatus) {
          WarrantyStatus.expiringSoon => 0,
          WarrantyStatus.active => 1,
          WarrantyStatus.expired => 2,
        };
    final items = all
        .where((p) => _filter == null || p.warrantyStatus == _filter)
        .toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return a.warrantyStatus == WarrantyStatus.expired
            ? b.warrantyPeriod.compareTo(a.warrantyPeriod)
            : a.warrantyPeriod.compareTo(b.warrantyPeriod);
      });

    final top = MediaQuery.of(context).padding.top + 88;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ModernAppBar(
        title: 'Warranty Center',
        subtitle: store.needsAttention.isEmpty
            ? 'All warranties are in good shape'
            : '${store.needsAttention.length} need${store.needsAttention.length == 1 ? 's' : ''} your attention',
      ),
      body: RefreshIndicator(
        onRefresh: store.refresh,
        edgeOffset: top,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top)),
            SliverToBoxAdapter(child: _buildFilters(store)),
            if (all.isEmpty && !store.isLoading)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.verified_user_rounded,
                  title: 'No warranties yet',
                  message:
                      'Add an appliance with its warranty date and we\'ll keep an eye on it for you.',
                  actionLabel: 'Add Appliance',
                  onAction: widget.onAdd,
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: _filter?.icon ?? Icons.inbox_rounded,
                  title: 'Nothing here',
                  message:
                      'No appliances are ${_filter?.label.toLowerCase() ?? 'listed'} right now.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => Entrance(
                    index: i,
                    child: _TimelineItem(
                      product: items[i],
                      isFirst: i == 0,
                      isLast: i == items.length - 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ProductStore store) {
    final options = <(WarrantyStatus?, String, int, Color)>[
      (null, 'All', store.count, AppColors.primary),
      for (final s in [
        WarrantyStatus.expiringSoon,
        WarrantyStatus.expired,
        WarrantyStatus.active,
      ])
        (s, s.label, store.withStatus(s).length, s.color),
    ];
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filter = o.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: _filter == o.$1 ? AppColors.shade(o.$4) : null,
                    color: _filter == o.$1 ? null : context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _filter == o.$1
                            ? Colors.white.withValues(alpha: 0.25)
                            : context.outline.withValues(alpha: 0.6)),
                    boxShadow: _filter == o.$1
                        ? AppShadows.glow(o.$4, strength: 0.8)
                        : AppShadows.raised(context, depth: 0.3),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${o.$2}  ${o.$3}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _filter == o.$1 ? Colors.white : context.textPrimary,
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

class _TimelineItem extends StatelessWidget {
  final Products product;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.product,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final status = product.warrantyStatus;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : context.outline,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.shade(status.color),
                    border: Border.all(color: context.background, width: 3),
                    boxShadow: AppShadows.glow(status.color),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : context.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: DepthCard(
                onTap: () => ProductPage.open(context, product),
                depth: 0.7,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProductThumb(type: product.type, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                              Text(
                                '${ProductUtils.categoryName(product.type)} • ${product.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: context.textMuted),
                              ),
                            ],
                          ),
                        ),
                        _DateBadge(date: product.warrantyPeriod, color: status.color),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WarrantyBar(product: product),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusPill(status: status, compact: true),
                        const Spacer(),
                        Text(
                          product.daysLeftLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendar-page style date badge.
class _DateBadge extends StatelessWidget {
  final DateTime date;
  final Color color;
  const _DateBadge({required this.date, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outline),
        boxShadow: AppShadows.raised(context, depth: 0.3),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              gradient: AppColors.shade(color),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              DateFormat('MMM').format(date).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
            ),
          ),
          Text('${date.day}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('${date.year}',
              style: TextStyle(fontSize: 9, color: context.textMuted)),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
