
import 'package:flutter/material.dart';

class MrzFramePainter extends CustomPainter {
  final bool isSuccess;

  MrzFramePainter({this.isSuccess = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSuccess ? Colors.green : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final borderRadius = 12.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.drawRRect(rrect, paint);

    if (isSuccess) {
      final glow = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawRRect(rrect, glow);
    }

    // Dessiner du texte MRZ d'exemple
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: (isSuccess ? Colors.green : Colors.white).withOpacity(0.3),
      fontSize: size.height * 0.18,
      fontFamily: 'monospace',
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    );

    // Ligne 1 du MRZ
    textPainter.text = TextSpan(
      text: 'IDCIV<<<<<<<<<<<<<<<<',
      style: textStyle,
    );
    textPainter.layout(maxWidth: size.width * 0.9);
    textPainter.paint(
      canvas,
      Offset(size.width * 0.05, size.height * 0.20),
    );

    // Ligne 2 du MRZ
    textPainter.text = TextSpan(
      text: '0123456789CIV901234<<',
      style: textStyle,
    );
    textPainter.layout(maxWidth: size.width * 0.9);
    textPainter.paint(
      canvas,
      Offset(size.width * 0.05, size.height * 0.58),
    );
  }

  @override
  bool shouldRepaint(covariant MrzFramePainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}