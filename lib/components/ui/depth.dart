import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/themes/app_colors.dart';

/// A raised card with layered shadows, a lit top edge, and — when tappable —
/// a press animation that sinks and tilts it toward the finger in 3D.
class DepthCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? color;
  final Color? glow;
  final bool tilt;
  final double depth;

  const DepthCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.gradient,
    this.color,
    this.glow,
    this.tilt = true,
    this.depth = 1,
  });

  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard> {
  bool _pressed = false;
  Offset _tilt = Offset.zero;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _updateTilt(Offset local, Size size) {
    if (!widget.tilt) return;
    final dx = (local.dx / size.width - 0.5).clamp(-0.5, 0.5);
    final dy = (local.dy / size.height - 0.5).clamp(-0.5, 0.5);
    setState(() => _tilt = Offset(dx, dy));
  }

  void _release() => setState(() {
        _pressed = false;
        _tilt = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hasFill = widget.gradient != null || widget.color != null;
    final baseColor = widget.color ?? context.surface;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      color: widget.gradient == null ? baseColor : null,
      gradient: widget.gradient ??
          (hasFill
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1C2040), AppColors.darkSurface]
                      : [Colors.white, const Color(0xFFFAFBFF)],
                )),
      border: Border.all(
        color: hasFill
            ? Colors.white.withValues(alpha: 0.18)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.9)),
        width: 1,
      ),
      boxShadow: _pressed
          ? AppShadows.pressed(context, glow: widget.glow)
          : AppShadows.raised(context, glow: widget.glow, depth: widget.depth),
    );

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          children: [
            // Specular highlight along the top edge.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 36,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(
                            alpha: hasFill ? 0.18 : (isDark ? 0.04 : 0.0)),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );

    if (!_interactive) return card;

    // Size is read at tap time rather than via LayoutBuilder so the card
    // still works inside intrinsic layouts (e.g. IntrinsicHeight).
    return GestureDetector(
      onTapDown: (d) {
        setState(() => _pressed = true);
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          _updateTilt(d.localPosition, box.size);
        }
      },
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _tilt),
        duration: const Duration(milliseconds: 180),
        builder: (context, tilt, child) {
          return AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 160),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-tilt.dy * 0.16)
                ..rotateY(tilt.dx * 0.16),
              child: child,
            ),
          );
        },
        child: card,
      ),
    );
  }
}

/// A glossy, sphere-like icon badge: a shaded fill, a specular highlight, and
/// a colored drop shadow.
class IconOrb extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final bool rounded;

  const IconOrb({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize,
    this.rounded = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = rounded ? BorderRadius.circular(size * 0.32) : null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: rounded ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: radius,
        gradient: AppColors.shade(color),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.18),
            spreadRadius: -size * 0.08,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.06,
            left: size * 0.12,
            right: size * 0.12,
            height: size * 0.42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(icon, color: Colors.white, size: iconSize ?? size * 0.5),
        ],
      ),
    );
  }
}

/// A chunky 3D push button: a gradient face sitting on a darker "edge" slab
/// that collapses when pressed.
class Button3D extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  final Color? edgeColor;
  final double height;
  final bool expand;

  const Button3D({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.gradient = AppColors.brandGradient,
    this.edgeColor,
    this.height = 56,
    this.expand = true,
  });

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> {
  bool _down = false;
  static const double _edge = 5;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final edgeColor =
        widget.edgeColor ?? AppColors.darken(widget.gradient.colors.last, 0.18);
    final offset = _down ? _edge : 0.0;

    final face = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: EdgeInsets.only(top: offset, bottom: _edge - offset),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: widget.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    final button = Opacity(
      opacity: widget.onPressed == null ? 0.55 : 1,
      child: Container(
        height: widget.height + _edge,
        width: widget.expand ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.glow(widget.gradient.colors.first,
              strength: _down ? 0.4 : 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edgeColor,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            face,
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: _enabled ? () => setState(() => _down = false) : null,
      onTap: _enabled
          ? () {
              HapticFeedback.mediumImpact();
              widget.onPressed!();
            }
          : null,
      child: button,
    );
  }
}

/// Soft floating blobs used behind hero headers for extra depth.
class FloatingOrbs extends StatefulWidget {
  final Color color;
  const FloatingOrbs({super.key, this.color = Colors.white});

  @override
  State<FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<FloatingOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          return Stack(
            children: [
              _orb(
                  right: -40 + 10 * math.sin(t),
                  top: -30 + 8 * math.cos(t),
                  size: 170,
                  alpha: 0.12),
              _orb(
                  left: -50 + 8 * math.cos(t),
                  bottom: -60 + 10 * math.sin(t),
                  size: 190,
                  alpha: 0.09),
              _orb(
                  right: 70 + 12 * math.cos(t),
                  bottom: 20 + 6 * math.sin(t),
                  size: 60,
                  alpha: 0.14),
            ],
          );
        },
      ),
    );
  }

  Widget _orb({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double alpha,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [
              widget.color.withValues(alpha: (alpha * 1.8).clamp(0.0, 1.0)),
              widget.color.withValues(alpha: (alpha * 0.3).clamp(0.0, 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}
