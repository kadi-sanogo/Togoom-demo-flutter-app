
import 'package:flutter/material.dart' ;

class ScanFramePainter extends CustomPainter {
  final bool isSuccess;

  ScanFramePainter({this.isSuccess = false});

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
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}
