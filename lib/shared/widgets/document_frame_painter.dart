import 'package:flutter/material.dart';

/// Painter générique et configurable pour cadre de document avec overlay
class DocumentFramePainter extends CustomPainter {
  final double frameWidthRatio;
  final double frameHeightRatio;
  final Color overlayColor;
  final double overlayOpacity;
  final Color cornerColor;
  final double cornerLength;
  final double cornerStrokeWidth;
  final double borderRadius;
  final bool showBorder;
  final Color borderColor;
  final double borderStrokeWidth;
  final bool useAspectRatio;
  final double? aspectRatio; // Largeur / Hauteur (ex: 1.586 pour ID card)

  DocumentFramePainter({
    this.frameWidthRatio = 0.85,
    this.frameHeightRatio = 0.65,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.7,
    this.cornerColor = Colors.white,
    this.cornerLength = 25.0,
    this.cornerStrokeWidth = 3.0,
    this.borderRadius = 0.0,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderStrokeWidth = 2.0,
    this.useAspectRatio = false,
    this.aspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double frameWidth;
    double frameHeight;

    if (useAspectRatio && aspectRatio != null) {
      frameWidth = size.width * frameWidthRatio;
      frameHeight = frameWidth / aspectRatio!;
    } else {
      frameWidth = size.width * frameWidthRatio;
      frameHeight = size.height * frameHeightRatio;
    }

    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    // Dessiner l'overlay sombre avec un trou transparent
    if (borderRadius > 0) {
      // Utiliser un path avec découpe arrondie
      final overlayPath = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)))
        ..fillType = PathFillType.evenOdd;

      final overlayPaint = Paint()
        ..color = overlayColor.withOpacity(overlayOpacity);

      canvas.drawPath(overlayPath, overlayPaint);
    } else {
      // Dessiner un overlay plein puis effacer le centre
      final backgroundPaint = Paint()
        ..color = overlayColor.withOpacity(overlayOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, backgroundPaint);

      canvas.saveLayer(null, Paint());
      canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
      canvas.restore();
    }

    // Dessiner la bordure si demandé
    if (showBorder) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderStrokeWidth;

      if (borderRadius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
          borderPaint,
        );
      } else {
        canvas.drawRect(rect, borderPaint);
      }
    }

    // Dessiner les coins
    _drawCorners(canvas, left, top, frameWidth, frameHeight);
  }

  void _drawCorners(
    Canvas canvas,
    double left,
    double top,
    double frameWidth,
    double frameHeight,
  ) {
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStrokeWidth;

    final cornerOffset = borderRadius > 0 ? borderRadius : 0.0;

    // Coin supérieur gauche
    canvas.drawLine(
      Offset(left, top + cornerLength + cornerOffset),
      Offset(left, top + cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerOffset, top),
      Offset(left + cornerLength + cornerOffset, top),
      cornerPaint,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength - cornerOffset, top),
      Offset(left + frameWidth - cornerOffset, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + cornerOffset),
      Offset(left + frameWidth, top + cornerLength + cornerOffset),
      cornerPaint,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(left, top + frameHeight - cornerLength - cornerOffset),
      Offset(left, top + frameHeight - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + cornerOffset, top + frameHeight),
      Offset(left + cornerLength + cornerOffset, top + frameHeight),
      cornerPaint,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength - cornerOffset, top + frameHeight),
      Offset(left + frameWidth - cornerOffset, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight - cornerOffset),
      Offset(left + frameWidth, top + frameHeight - cornerLength - cornerOffset),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DocumentFramePainter oldDelegate) {
    return oldDelegate.frameWidthRatio != frameWidthRatio ||
        oldDelegate.frameHeightRatio != frameHeightRatio ||
        oldDelegate.overlayOpacity != overlayOpacity ||
        oldDelegate.cornerColor != cornerColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}