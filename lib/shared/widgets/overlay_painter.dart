
import 'package:flutter/material.dart';

class OverlayPainter extends CustomPainter {
  final bool captureSuccess;
  final Rect frameRect;

  OverlayPainter({required this.captureSuccess, required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final borderRadius = 12.0;
    final rrect = RRect.fromRectAndRadius(frameRect, Radius.circular(borderRadius));

    // Créer un path pour tout l'écran
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Créer un path pour le cadre arrondi
    final framePath = Path()
      ..addRRect(rrect);

    // Soustraire le cadre du plein écran pour créer le masque
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      framePath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.captureSuccess != captureSuccess ||
          oldDelegate.frameRect != frameRect;
}
