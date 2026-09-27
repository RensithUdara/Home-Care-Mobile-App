import 'package:flutter/material.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:home_care/utils/warranty.dart';

/// Tall card for the two-column grid.
class ProductGridCard extends StatelessWidget {
  final Products product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = product.warrantyStatus;
    final color = ProductUtils.colorOf(product.type);
    return DepthCard(
      onTap: onTap,
      onLongPress: onLongPress,
      glow: color,
      depth: 0.8,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'product_${product.id}',
                child: ProductThumb(type: product.type, size: 58),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(status.color),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 13, color: context.textMuted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  product.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WarrantyBar(product: product, height: 5),
          const SizedBox(height: 6),
          Text(
            product.daysLeftLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide row card for list mode.
class ProductListCard extends StatelessWidget {
  final Products product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ProductListCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return DepthCard(
      onTap: onTap,
      onLongPress: onLongPress,
      depth: 0.7,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Hero(
            tag: 'product_${product.id}',
            child: ProductThumb(type: product.type, size: 60),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(status: product.warrantyStatus, compact: true),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (product.brand != null) product.brand!,
                    product.location,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: context.textMuted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: WarrantyBar(product: product, height: 5)),
                    const SizedBox(width: 10),
                    Text(
                      product.daysLeftLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: product.warrantyStatus.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card for the horizontal "needs attention" carousel.
class AttentionCard extends StatelessWidget {
  final Products product;
  final VoidCallback onTap;
  const AttentionCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = product.warrantyStatus;
    return SizedBox(
      width: 230,
      child: DepthCard(
        onTap: onTap,
        gradient: AppColors.shade(status.color),
        glow: status.color,
        depth: 0.8,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                ProductUtils.getImagePath(ProductUtils.typeKey(product.type)),
                errorBuilder: (_, __, ___) => Icon(
                    ProductUtils.iconOf(product.type),
                    color: status.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(status.icon, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.daysLeftLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
