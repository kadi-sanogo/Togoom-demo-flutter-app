import 'package:flutter/material.dart';

/// Painter générique pour cadre circulaire avec overlay
class CircularFramePainter extends CustomPainter {
  final double radiusRatio;
  final Color overlayColor;
  final double overlayOpacity;
  final Color circleColor;
  final double circleStrokeWidth;
  final bool isSuccess;
  final Color successColor;
  final bool showGlow;
  final double glowRadius;
  final double glowStrokeWidth;
  final Offset? centerOffset; // Offset personnalisé du centre (null = centre par défaut)

  // Progress arc parameters
  final bool showProgressArc;
  final double progressValue; // 0.0 to 1.0
  final Color? progressColor;
  final double progressStrokeWidth;
  final double progressArcOffset;

  CircularFramePainter({
    this.radiusRatio = 0.35,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.7,
    this.circleColor = Colors.white,
    this.circleStrokeWidth = 3.0,
    this.isSuccess = false,
    this.successColor = Colors.green,
    this.showGlow = true,
    this.glowRadius = 5.0,
    this.glowStrokeWidth = 8.0,
    this.centerOffset,
    this.showProgressArc = false,
    this.progressValue = 0.0,
    this.progressColor,
    this.progressStrokeWidth = 8.0,
    this.progressArcOffset = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculer le centre (utiliser l'offset personnalisé ou le centre par défaut)
    final center = centerOffset ?? Offset(size.width / 2, size.height / 2);
    final radius = size.width * radiusRatio;

    // Dessiner l'overlay sombre
    final overlayPaint = Paint()
      ..color = overlayColor.withOpacity(overlayOpacity);

    canvas.saveLayer(null, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Créer un trou transparent au centre
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);
    canvas.restore();

    // Dessiner le cercle de guidage
    final circleColor = isSuccess ? successColor : this.circleColor;
    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = circleStrokeWidth;

    canvas.drawCircle(center, radius, circlePaint);

    // Ajouter un effet de glow si succès
    if (isSuccess && showGlow) {
      final glowPaint = Paint()
        ..color = successColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(center, radius + glowRadius, glowPaint);
    }

    // Dessiner l'arc de progression si activé
    if (showProgressArc && progressValue > 0) {
      final effectiveProgressColor = progressColor ??
        (progressValue >= 0.7 ? Colors.green : Colors.amber);

      final progressPaint = Paint()
        ..color = effectiveProgressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = progressStrokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * progressValue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + progressArcOffset),
        -3.14159 / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularFramePainter oldDelegate) {
    return oldDelegate.radiusRatio != radiusRatio ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.circleColor != circleColor ||
        oldDelegate.overlayOpacity != overlayOpacity ||
        oldDelegate.progressValue != progressValue ||
        oldDelegate.showProgressArc != showProgressArc;
  }
}