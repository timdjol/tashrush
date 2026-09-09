import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/game_constants.dart';

class KyrgyzPatternBackground extends StatelessWidget {
  const KyrgyzPatternBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [RushPalette.canvas, RushPalette.sand],
          ),
        ),
        child: CustomPaint(
          painter: const KyrgyzPatternPainter(),
          child: child,
        ),
      );
}

class KyrgyzPatternPainter extends CustomPainter {
  const KyrgyzPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..color = RushPalette.coral.withAlpha(24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final gold = Paint()
      ..color = RushPalette.gold.withAlpha(24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double x = -18; x < size.width + 36; x += 48) {
      _drawDiamond(canvas, Offset(x, 24), 12, red);
      _drawDiamond(canvas, Offset(x + 24, size.height - 24), 12, red);
      canvas.drawCircle(Offset(x + 24, 24), 4, gold);
      canvas.drawCircle(Offset(x, size.height - 24), 4, gold);
    }

    _drawHorn(canvas, const Offset(12, 92), red, clockwise: true);
    _drawHorn(canvas, Offset(size.width - 12, 92), red, clockwise: false);
    _drawHorn(canvas, Offset(12, size.height - 92), gold, clockwise: false);
    _drawHorn(
      canvas,
      Offset(size.width - 12, size.height - 92),
      gold,
      clockwise: true,
    );
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHorn(
    Canvas canvas,
    Offset center,
    Paint paint, {
    required bool clockwise,
  }) {
    final direction = clockwise ? 1.0 : -1.0;
    final path = Path()..moveTo(center.dx, center.dy - 34);
    path.cubicTo(
      center.dx + 38 * direction,
      center.dy - 34,
      center.dx + 38 * direction,
      center.dy + 28,
      center.dx,
      center.dy + 28,
    );
    path.cubicTo(
      center.dx - 20 * direction,
      center.dy + 28,
      center.dx - 20 * direction,
      center.dy,
      center.dx,
      center.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant KyrgyzPatternPainter oldDelegate) => false;
}

class TundukEmblem extends StatelessWidget {
  const TundukEmblem({this.size = 92, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: const _TundukPainter()),
      );
}

class _TundukPainter extends CustomPainter {
  const _TundukPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .36;
    final glow = Paint()
      ..color = RushPalette.gold.withAlpha(35)
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = RushPalette.gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .055;
    final red = Paint()
      ..color = RushPalette.coral
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .075;

    canvas.drawCircle(center, radius * 1.22, glow);
    canvas.drawCircle(center, radius, red);
    for (var index = 0; index < 4; index++) {
      final angle = index * math.pi / 4;
      final offset = Offset(math.cos(angle), math.sin(angle));
      final start = center + offset * radius;
      final end = center - offset * radius;
      canvas.drawLine(start, end, gold);
    }
    canvas.drawCircle(center, radius * .18, red..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _TundukPainter oldDelegate) => false;
}

class EthnoDivider extends StatelessWidget {
  const EthnoDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 46, height: 2, color: RushPalette.gold),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.diamond_outlined,
              size: 18,
              color: RushPalette.coral,
            ),
          ),
          Container(width: 46, height: 2, color: RushPalette.gold),
        ],
      );
}
