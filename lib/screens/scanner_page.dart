import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/components/ui/common.dart';
import 'package:home_care/themes/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode / QR scanner. Pops with the scanned text, or null.
class ScannerPage extends StatefulWidget {
  final String title;
  final String hint;

  const ScannerPage({super.key, required this.title, required this.hint});

  static Future<String?> scan(
    BuildContext context, {
    String title = 'Scan barcode',
    String hint = 'Point at the barcode or QR code on the appliance label',
  }) {
    return Navigator.of(context).push<String>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ScannerPage(title: title, hint: hint),
    ));
  }

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _done = false;

  @override
  void dispose() {
    _line.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _finish(String value) {
    if (_done) return;
    _done = true;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(value);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final value = b.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _finish(value);
        return;
      }
    }
  }

  Future<void> _fromPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    try {
      final result = await _controller.analyzeImage(image.path);
      final value = result?.barcodes
          .map((b) => b.rawValue?.trim())
          .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
      if (value != null) {
        _finish(value);
      } else if (mounted) {
        AppSnack.error(context, 'No barcode found in that photo');
      }
    } catch (_) {
      if (mounted) AppSnack.error(context, 'Could not read that photo');
    }
  }

  Rect _window(Size size) {
    final width = (size.width * 0.78).clamp(220.0, 360.0);
    final height = width * 0.62;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          final window = _window(size);
          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: window,
                onDetect: _onDetect,
                errorBuilder: (context, error) => _ErrorView(error: error),
              ),
              // Dimmed surround with a clear window.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _MaskPainter(window)),
                ),
              ),
              // Glowing corners and moving scan line.
              Positioned.fromRect(
                rect: window,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _line,
                    builder: (context, _) => CustomPaint(
                      painter: _FramePainter(
                          Curves.easeInOut.transform(_line.value)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: window.bottom + 24,
                left: 32,
                right: 32,
                child: Text(
                  widget.hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _GlassButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, _) {
                            final on = state.torchState == TorchState.on;
                            final available =
                                state.torchState != TorchState.unavailable;
                            return _GlassButton(
                              icon: on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              label: 'Torch',
                              active: on,
                              onTap: available ? _controller.toggleTorch : null,
                            );
                          },
                        ),
                        _GlassButton(
                          icon: Icons.photo_library_rounded,
                          label: 'From photo',
                          onTap: _fromPhoto,
                        ),
                        _GlassButton(
                          icon: Icons.cameraswitch_rounded,
                          label: 'Flip',
                          onTap: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _GlassButton({
    required this.icon,
    this.label,
    this.tooltip,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: label == null ? 44 : 58,
              height: label == null ? 44 : 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? AppColors.sunsetGradient : null,
                color: active ? null : Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: active ? AppShadows.glow(AppColors.warning) : null,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(label!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _ErrorView extends StatelessWidget {
  final MobileScannerException error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(denied ? Icons.no_photography_rounded : Icons.error_rounded,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              Text(
                denied ? 'Camera access needed' : 'Camera unavailable',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                denied
                    ? 'Allow camera access in your phone settings to scan, or use "From photo" below.'
                    : 'The camera could not be started. You can still scan from a photo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final Rect window;
  _MaskPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(24)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.window != window;
}

class _FramePainter extends CustomPainter {
  final double t;
  _FramePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const len = 30.0;
    const r = 24.0;
    final glow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final w = size.width, h = size.height;
    final corners = [
      Path()
        ..moveTo(0, len + r)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len + r, 0),
      Path()
        ..moveTo(w - len - r, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, len + r),
      Path()
        ..moveTo(w, h - len - r)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
        ..lineTo(w - len - r, h),
      Path()
        ..moveTo(len + r, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
        ..lineTo(0, h - len - r),
    ];
    for (final c in corners) {
      canvas.drawPath(c, glow);
      canvas.drawPath(c, line);
    }

    final y = 16 + (h - 32) * t;
    final scan = Rect.fromLTWH(16, y - 1.5, w - 32, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scan.inflate(4), const Radius.circular(6)),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(scan, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(colors: [
          AppColors.accent.withValues(alpha: 0),
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0),
        ]).createShader(scan),
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.t != t;
}
