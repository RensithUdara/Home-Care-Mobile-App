import 'package:flutter/material.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/models/products.dart';
import 'package:home_care/utils/product_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a product summary, falling back to a
/// snackbar if sharing isn't available.
Future<void> shareProduct(BuildContext context, Products product) async {
  // iPad needs an anchor rect for the share popover.
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  try {
    await SharePlus.instance.share(ShareParams(
      text: ProductUtils.shareText(product),
      subject: product.name,
      sharePositionOrigin: origin,
    ));
  } catch (_) {
    if (context.mounted) AppSnack.error(context, 'Sharing is not available');
  }
}
