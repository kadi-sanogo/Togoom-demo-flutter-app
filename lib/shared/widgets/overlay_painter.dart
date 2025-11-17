
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

    // Zone au-dessus du cadre
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, frameRect.top), paint);

    // Zone en-dessous du cadre
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        frameRect.bottom,
        size.width,
        size.height - frameRect.bottom,
      ),
      paint,
    );

    // Zone à gauche du cadre
    canvas.drawRect(
      Rect.fromLTWH(0, frameRect.top, frameRect.left, frameRect.height),
      paint,
    );

    // Zone à droite du cadre
    canvas.drawRect(
      Rect.fromLTWH(
        frameRect.right,
        frameRect.top,
        size.width - frameRect.right,
        frameRect.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.captureSuccess != captureSuccess ||
          oldDelegate.frameRect != frameRect;
}
