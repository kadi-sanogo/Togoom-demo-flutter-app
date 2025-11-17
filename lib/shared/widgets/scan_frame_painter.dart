
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

    final cornerLength = 30.0;

    void drawCorner(Offset start, Offset end1, Offset end2) {
      canvas.drawLine(start, end1, paint);
      canvas.drawLine(start, end2, paint);
    }

    drawCorner(Offset(0, 0), Offset(cornerLength, 0), Offset(0, cornerLength));
    drawCorner(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      Offset(size.width, cornerLength),
    );
    drawCorner(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      Offset(0, size.height - cornerLength),
    );
    drawCorner(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height - cornerLength),
    );

    if (isSuccess) {
      final glow = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawRect(Offset.zero & size, glow);
    }
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}
