import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Kwago, the HulaSalita owl mascot, with an optional speech bubble.
class Kwago extends StatelessWidget {
  const Kwago({super.key, this.message, this.size = 64, this.onNight = true});

  final String? message;
  final double size;
  final bool onNight; // bubble colors for the dark background

  @override
  Widget build(BuildContext context) {
    final owl = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text('🦉', style: TextStyle(fontSize: size * 0.82, height: 1)),
          Positioned(top: -size * 0.12, child: Text('🎓', style: TextStyle(fontSize: size * 0.36, height: 1))),
        ],
      ),
    );
    if (message == null) return owl;

    final bubbleColor = onNight ? AppColors.nightCard : AppColors.navySoft;
    final textColor = onNight ? Colors.white : AppColors.navy;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        owl,
        const SizedBox(width: 6),
        CustomPaint(size: const Size(10, 16), painter: _Tail(bubbleColor)),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
              border: onNight ? Border.all(color: AppColors.nightLine) : null,
            ),
            child: Text(message!, style: displayStyle(size: 15, color: textColor, weight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _Tail extends CustomPainter {
  _Tail(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Tail oldDelegate) => oldDelegate.color != color;
}
