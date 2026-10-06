import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

class PngScenicBackdrop extends StatelessWidget {
  const PngScenicBackdrop({
    required this.child,
    this.height,
    this.minHeight = 0,
    this.padding = const EdgeInsets.all(18),
    this.colors,
    super.key,
  });

  final Widget child;
  final double? height;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    colors ??
                    const [
                      Color(0xFF075C3A),
                      Color(0xFF087A4B),
                      Color(0xFF0B79A8),
                    ],
              ),
            ),
            child: CustomPaint(
              painter: const PngLandscapePainter(),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class PngLandscapePainter extends CustomPainter {
  const PngLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = const Color(0xFFF7C94A).withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.22),
      size.shortestSide * 0.11,
      sun,
    );

    _drawMountains(
      canvas,
      size,
      baseY: size.height * 0.62,
      peakScale: 0.24,
      color: const Color(0xFF0E4B43).withValues(alpha: 0.72),
      phase: 0.2,
    );
    _drawMountains(
      canvas,
      size,
      baseY: size.height * 0.72,
      peakScale: 0.19,
      color: const Color(0xFF173D34).withValues(alpha: 0.88),
      phase: 1.1,
    );

    final hill = Path()
      ..moveTo(0, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.23,
        size.height * 0.66,
        size.width * 0.48,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.9,
        size.width,
        size.height * 0.73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      hill,
      Paint()..color = const Color(0xFF184D30).withValues(alpha: 0.94),
    );

    final foreground = Path()
      ..moveTo(0, size.height * 0.87)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.79,
        size.width * 0.37,
        size.height * 0.9,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 1.02,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      foreground,
      Paint()..color = const Color(0xFF0A2B22).withValues(alpha: 0.62),
    );

    _drawBirdOfParadise(canvas, size);
    _drawPalmLeaves(canvas, size);
  }

  void _drawMountains(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double peakScale,
    required Color color,
    required double phase,
  }) {
    final path = Path()..moveTo(0, baseY);
    const points = 7;
    for (var index = 0; index <= points; index++) {
      final x = size.width * index / points;
      final wave = math.sin(index * 1.7 + phase).abs();
      final y = baseY - size.height * peakScale * (0.35 + wave * 0.65);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBirdOfParadise(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.87, size.height * 0.65);
    final red = Paint()
      ..color = const Color(0xFFE84C35).withValues(alpha: 0.88)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    final gold = Paint()
      ..color = const Color(0xFFF7B729).withValues(alpha: 0.92)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    for (var i = 0; i < 4; i++) {
      final angle = -1.9 + i * 0.38;
      final end = origin + Offset(math.cos(angle), math.sin(angle)) * 44;
      canvas.drawLine(origin, end, i.isEven ? red : gold);
    }
    canvas.drawCircle(origin, 7, Paint()..color = const Color(0xFF111111));
  }

  void _drawPalmLeaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final base = Offset(size.width * 0.05, size.height * 0.12);
    for (var i = 0; i < 5; i++) {
      final angle = 0.2 + i * 0.28;
      final end = base + Offset(math.cos(angle), math.sin(angle)) * 52;
      canvas.drawLine(base, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PngLandscapePainter oldDelegate) => false;
}

class BilumPatternPainter extends CustomPainter {
  const BilumPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF4C26A).withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const step = 24.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        final diamond = Path()
          ..moveTo(x, y + step / 2)
          ..lineTo(x + step / 2, y)
          ..lineTo(x + step, y + step / 2)
          ..lineTo(x + step / 2, y + step)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BilumPatternPainter oldDelegate) => false;
}

class KinaBadge extends StatelessWidget {
  const KinaBadge({
    required this.amount,
    this.background = const Color(0xFFF5B82E),
    this.foreground = const Color(0xFF2A1B05),
    super.key,
  });

  final num amount;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final decimals = amount % 1 == 0 ? 0 : 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          'K${amount.toStringAsFixed(decimals)}',
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class PngSectionTitle extends StatelessWidget {
  const PngSectionTitle({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...<Widget?>[trailing].whereType<Widget>(),
      ],
    );
  }
}
