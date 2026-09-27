import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/product_form_sheet.dart';
import 'package:home_care/screens/home.dart';
import 'package:home_care/screens/insights.dart';
import 'package:home_care/screens/profile.dart';
import 'package:home_care/screens/warranty.dart';
import 'package:home_care/services/product_store.dart';
import 'package:home_care/services/reminder_service.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:provider/provider.dart';

/// Signed-in root: four tabs behind a floating 3D navigation bar with a
/// raised center "add" button.
class MainShell extends StatefulWidget {
  final String uid;
  final String email;
  const MainShell({super.key, required this.uid, required this.email});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    ReminderService.instance.requestPermissionOnce();
  }

  void _goTo(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _add() {
    final store = context.read<ProductStore>();
    ProductFormSheet.show(context, uid: widget.uid, onSaved: store.refresh);
  }

  @override
  Widget build(BuildContext context) {
    final attention = context.select<ProductStore, int>((s) => s.alertCount);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(email: widget.email, onNavigate: _goTo, onAdd: _add),
          InsightsTab(onAdd: _add),
          WarrantyTab(onAdd: _add),
          ProfilePage(email: widget.email),
        ],
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        onTap: _goTo,
        onAdd: _add,
        warrantyBadge: attention,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  final int warrantyBadge;

  const _NavBar({
    required this.index,
    required this.onTap,
    required this.onAdd,
    required this.warrantyBadge,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 14),
      child: SizedBox(
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                ),
                boxShadow: AppShadows.raised(context, depth: 1.2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final centerGap = constraints.maxWidth < 320 ? 56.0 : 72.0;
                  return Row(
                    children: [
                      _item(context, 0, Icons.home_rounded, 'Home'),
                      _item(context, 1, Icons.insights_rounded, 'Insights'),
                      SizedBox(width: centerGap),
                      _item(context, 2, Icons.verified_user_rounded, 'Warranty',
                          badge: warrantyBadge),
                      _item(context, 3, Icons.person_rounded, 'Profile'),
                    ],
                  );
                },
              ),
            ),
            Positioned(top: 0, child: _AddButton(onTap: onAdd)),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, IconData icon, String label,
      {int badge = 0}) {
    final selected = i == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth;
            final iconSize = itemWidth < 34 ? 18.0 : 22.0;
            final horizontalPadding =
                math.max(0.0, math.min(14.0, (itemWidth - iconSize) / 2));
            final showLabel = itemWidth >= 48;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.brandGradient : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selected
                            ? AppShadows.glow(AppColors.primary, strength: 0.8)
                            : null,
                      ),
                      child: Icon(icon,
                          size: iconSize,
                          color: selected ? Colors.white : context.textMuted),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: math.min(4.0, horizontalPadding),
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: context.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showLabel) ...[
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.primary : context.textMuted,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            border: Border.all(color: context.background, width: 4),
            boxShadow:
                AppShadows.glow(AppColors.primary, strength: _down ? 0.5 : 1.3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 4,
                left: 10,
                right: 10,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
