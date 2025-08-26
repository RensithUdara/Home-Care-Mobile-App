import 'package:flutter/material.dart';

class BottomAddBar extends StatefulWidget {
  final int productCount;
  final Function onTap;
  const BottomAddBar(
      {super.key, required this.productCount, required this.onTap});

  @override
  State<BottomAddBar> createState() => _BottomAddBarState();
}

class _BottomAddBarState extends State<BottomAddBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    "${widget.productCount} Products.",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        widget.onTap();
                      },
                      child: const Icon(
                        Icons.add,
                        color: Colors.limeAccent,
                        size: 40,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
