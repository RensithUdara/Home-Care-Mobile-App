import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:home_care/components/ui/depth.dart';
import 'package:home_care/services/auth/auth_check.dart';
import 'package:home_care/themes/app_colors.dart';

/// Brand intro: the logo spins in on a 3D axis, then hands off to auth.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const AuthCheck(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spin = CurvedAnimation(
        parent: _c, curve: const Interval(0, 0.65, curve: Curves.easeOutBack));
    final text = CurvedAnimation(
        parent: _c, curve: const Interval(0.45, 1, curve: Curves.easeOut));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingOrbs()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: spin,
                    builder: (context, child) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateY((1 - spin.value) * math.pi)
                        ..scaleByDouble(0.6 + 0.4 * spin.value,
                            0.6 + 0.4 * spin.value, 1, 1),
                      child: Opacity(
                          opacity: spin.value.clamp(0.0, 1.0), child: child),
                    ),
                    child: const _LogoBlock(),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: text,
                    child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                              .animate(text),
                      child: Column(
                        children: [
                          const Text(
                            'Home Care',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your appliances, warranties & support — in one place',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded,
              size: 64, color: AppColors.primary),
        ),
      ),
    );
  }
}
