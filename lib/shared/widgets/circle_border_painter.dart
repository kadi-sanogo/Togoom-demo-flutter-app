import 'package:flutter/material.dart';

/// Painter simple pour dessiner juste une bordure circulaire
class CircleBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double? radiusRatio;
  final double? radius; // Radius absolu (prioritaire sur radiusRatio)

  CircleBorderPainter({
    required this.color,
    this.strokeWidth = 3.0,
    this.radiusRatio,
    this.radius,
  }) : assert(radius != null || radiusRatio != null,
            'Either radius or radiusRatio must be provided');

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);

    // Utiliser radius absolu si fourni, sinon calculer à partir du ratio
    final effectiveRadius = radius ?? (size.width * (radiusRatio ?? 0.35));

    canvas.drawCircle(center, effectiveRadius - strokeWidth / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CircleBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radiusRatio != radiusRatio ||
        oldDelegate.radius != radius;
  }
}