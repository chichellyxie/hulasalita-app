import 'dart:math';

import 'package:flutter/material.dart';

/// A one-time burst of colorful confetti (no extra package needed).
/// Place it in a Stack above the content; it ignores touches.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 90, this.duration = const Duration(milliseconds: 2400)});

  final int pieces;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Piece> _pieces = _make();

  static const _colors = [
    Color(0xFFF2B233), Color(0xFFE4A4B7), Color(0xFFB2A6F4), Color(0xFF9FC6F4),
    Color(0xFFA6D3B3), Color(0xFFEFBB8E), Color(0xFFFFFFFF), Color(0xFF17734A),
  ];

  List<_Piece> _make() {
    final r = Random();
    return List.generate(widget.pieces, (i) {
      final angle = -pi / 2 + (r.nextDouble() - 0.5) * pi * 0.9; // mostly upward
      final speed = 420 + r.nextDouble() * 520;
      return _Piece(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: _colors[r.nextInt(_colors.length)],
        w: 6 + r.nextDouble() * 6,
        h: 4 + r.nextDouble() * 6,
        spin: (r.nextDouble() - 0.5) * 14,
        startX: 0.3 + r.nextDouble() * 0.4,
        round: r.nextInt(4) == 0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ClipRect keeps every piece inside this widget's area, so confetti
    // never shows outside the result sheet.
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value * widget.duration.inMilliseconds / 1000),
        ),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({required this.vx, required this.vy, required this.color, required this.w, required this.h, required this.spin, required this.startX, required this.round});

  final double vx, vy, w, h, spin, startX;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t; // seconds since the burst

  static const _gravity = 900.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t > 1.6 ? (1 - (t - 1.6) / 0.8).clamp(0.0, 1.0) : 1.0;
    final paint = Paint();
    for (final p in pieces) {
      final x = size.width * p.startX + p.vx * t * 0.6;
      final y = size.height * 0.38 + p.vy * t + 0.5 * _gravity * t * t;
      if (y > size.height + 20) continue;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.w / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
