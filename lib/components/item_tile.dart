import 'package:flutter/material.dart';
import 'package:home_care/models/products.dart';

import 'package:home_care/utils/product_utils.dart';

class ItemTile extends StatefulWidget {
  final Products product;
  const ItemTile({super.key, required this.product});

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> {
  @override
  Widget build(BuildContext context) {
    String typeName = ProductUtils.getTypeName(widget.product.type.toString());
    Color color = ProductUtils.getColor(typeName);
    return Container(
      margin: const EdgeInsets.only(top: 10.0, left: 5, right: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    child: Image.asset(
                      ProductUtils.getImagePath(typeName),
                      height: 80,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProductUtils.getDisplayName(widget.product.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.product.location,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        typeName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.inversePrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.limeAccent,
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: 2.2,
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
