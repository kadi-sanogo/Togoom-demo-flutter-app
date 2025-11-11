import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomCameraScreen extends StatefulWidget {
  final String documentType;
  final Function(String) onImageCaptured;

  const CustomCameraScreen({
    super.key,
    required this.documentType,
    required this.onImageCaptured,
    required bool requiresVerso,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Navigator.pop(context);
      return;
    }

    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      widget.onImageCaptured(image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de capture : $e")));
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          CustomPaint(size: Size.infinite, painter: DocScanOverlayPainter()),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  widget.documentType == "recto"
                      ? "Scannez le recto de votre pièce"
                      : "Scannez le verso de votre pièce",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.85;
    final frameHeight = frameWidth * 0.65;

    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final rect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    canvas.saveLayer(null, Paint());
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, borderPaint);

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerLength = 25.0;
    // Haut-gauche
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );
    // Haut-droite
    canvas.drawLine(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth, top + cornerLength),
      cornerPaint,
    );
    // Bas-gauche
    canvas.drawLine(
      Offset(left, top + frameHeight),
      Offset(left + cornerLength, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + frameHeight),
      Offset(left, top + frameHeight - cornerLength),
      cornerPaint,
    );
    // Bas-droite
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight),
      Offset(left + frameWidth - cornerLength, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
