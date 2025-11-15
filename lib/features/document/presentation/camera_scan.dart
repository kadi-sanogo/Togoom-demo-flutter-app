import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/verification/language_service.dart';

class CustomCameraScreen extends StatefulWidget {
  final Function(String imagePath) onImageCaptured;
  final String documentType; 

  const CustomCameraScreen({
    super.key,
    required this.onImageCaptured,
    required this.documentType,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
  if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
    return;
  }

  setState(() {
    _isCapturing = true;
  });

  try {
    final XFile photo = await _controller!.takePicture();
    widget.onImageCaptured(photo.path);
  } catch (e) {
    print('Erreur lors de la capture: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de la capture")),
    );
  } finally {
    setState(() {
      _isCapturing = false;
    });
  }
}


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Aperçu de la caméra
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          Positioned.fill(
            child: CustomPaint(
              painter: DocumentFramePainter(),
              child: Container(),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.documentType == "recto" 
                              ? "Capture du recto" 
                              : "Capture du verso",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Positionnez votre document dans le cadre",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.15,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.documentType == "recto"
                    ? "Placez le recto de votre pièce d'identité\ndans le cadre ci-dessous"
                    : "Placez le verso de votre pièce d'identité\ndans le cadre ci-dessous",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 60),
                  
                  GestureDetector(
                    onTap: _isCapturing ? null : _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isCapturing 
                            ? Colors.grey.withOpacity(0.5)
                            : AppColors.secondary,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double frameRatio = 1.586;
    final double frameWidth = size.width * 0.8;
    final double frameHeight = frameWidth / frameRatio;
    
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;

    // Zone du cadre
    final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    
    canvas.drawPath(overlayPath, overlayPaint);

    final cornerPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerSize = 30;

    //  supérieur gauche
    canvas.drawLine(
      Offset(left, top + cornerSize),
      Offset(left, top + 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 12, top),
      Offset(left + cornerSize, top),
      cornerPaint,
    );

    //  supérieur droit
    canvas.drawLine(
      Offset(left + frameWidth - cornerSize, top),
      Offset(left + frameWidth - 12, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + 12),
      Offset(left + frameWidth, top + cornerSize),
      cornerPaint,
    );

    //  inférieur gauche
    canvas.drawLine(
      Offset(left, top + frameHeight - cornerSize),
      Offset(left, top + frameHeight - 12),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 12, top + frameHeight),
      Offset(left + cornerSize, top + frameHeight),
      cornerPaint,
    );

    //  inférieur droit
    canvas.drawLine(
      Offset(left + frameWidth - cornerSize, top + frameHeight),
      Offset(left + frameWidth - 12, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight - 12),
      Offset(left + frameWidth, top + frameHeight - cornerSize),
      cornerPaint,
    );

    // Dessiner une bordure subtile autour du cadre
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}