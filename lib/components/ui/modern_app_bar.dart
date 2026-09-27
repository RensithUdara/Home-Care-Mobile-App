import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/themes/app_colors.dart';

/// Frosted-glass app bar with an optional subtitle and 3D icon actions.
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  const ModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: context.background.withValues(alpha: 0.78),
            border: Border(
              bottom: BorderSide(color: context.outline.withValues(alpha: 0.5)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (showBack) ...[
                      AppBarIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: 'Back',
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final a in actions) ...[const SizedBox(width: 8), a],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square, raised icon button used in app bars.
class AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final int badge;
  final Color? color;
  final bool onGradient;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badge = 0,
    this.color,
    this.onGradient = false,
  });

  @override
  State<AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<AppBarIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.color ??
        (widget.onGradient ? Colors.white : context.textPrimary);
    final bg = widget.onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : context.surface;

    Widget button = AnimatedScale(
      scale: _down ? 0.9 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.onGradient
                ? Colors.white.withValues(alpha: 0.28)
                : context.outline.withValues(alpha: 0.6),
          ),
          boxShadow: widget.onGradient
              ? null
              : AppShadows.raised(context, depth: _down ? 0.2 : 0.45),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(widget.icon, size: 20, color: fg),
            if (widget.badge > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 19),
                  decoration: BoxDecoration(
                    gradient: AppColors.sunsetGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            widget.onGradient ? Colors.white : context.surface,
                        width: 2),
                  ),
                  child: Text(
                    widget.badge > 9 ? '9+' : '${widget.badge}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    button = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: button,
    );

    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
