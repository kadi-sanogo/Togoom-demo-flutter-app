import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:togoom/core/theme/app_colors.dart';

class EyeVerificationScreen extends StatefulWidget {
  final Function(Uint8List)? onEyesCaptured;

  const EyeVerificationScreen({super.key, this.onEyesCaptured});

  @override
  State<EyeVerificationScreen> createState() => _EyeVerificationScreenState();
}

class _EyeVerificationScreenState extends State<EyeVerificationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _guidanceMessage = "Placez votre visage dans le cercle";
  bool _faceDetected = false;
  bool _eyesOpen = false;
  bool _isProcessing = false;
  double _leftEyeOpenProbability = 0.0;
  double _rightEyeOpenProbability = 0.0;

  // ML Kit Face Detector
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _checkPermissions();

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() => _isCameraInitialized = true);
      _startFaceDetection();
    }
  }

  Future<void> _checkPermissions() async {
    var result = await Permission.camera.request();
    if (!result.isGranted && mounted) {
      Navigator.pop(context);
    }
  }

  void _startFaceDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCapturing) return;
      _isProcessing = true;

      try {
        final inputImage = _convertToInputImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);

          if (mounted) {
            _analyzeFaces(faces);
          }
        }
      } catch (e) {
        debugPrint("Erreur détection: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      debugPrint("Erreur conversion image: $e");
      return null;
    }
  }

  void _analyzeFaces(List<Face> faces) {
    if (faces.isEmpty) {
      if (mounted) {
        setState(() {
          _faceDetected = false;
          _eyesOpen = false;
          _leftEyeOpenProbability = 0.0;
          _rightEyeOpenProbability = 0.0;
          _guidanceMessage = "Aucun visage détecté";
        });
      }
      return;
    }

    final face = faces.first;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;

    if (mounted) {
      setState(() {
        _leftEyeOpenProbability = leftEyeOpen;
        _rightEyeOpenProbability = rightEyeOpen;
        _faceDetected = leftEye != null && rightEye != null;
        _eyesOpen = leftEyeOpen >= 0.4 && rightEyeOpen >= 0.4;
      });
    }

    if (!_faceDetected) {
      _guidanceMessage = "Visage non centré";
    } else if (leftEyeOpen < 0.4 || rightEyeOpen < 0.4) {
      _guidanceMessage = "Ouvrez bien les yeux";
    } else {
      _guidanceMessage = "Appuyez sur le bouton pour capturer";
    }
  }

  Future<void> _captureEyes() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      await _cameraController?.stopImageStream();

      final XFile picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();

      if (widget.onEyesCaptured != null) {
        widget.onEyesCaptured!(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Photo prise avec succès !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur de capture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la capture: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
        // Redémarrer le stream si besoin
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_cameraController?.value.isInitialized == true) {
            _startFaceDetection();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F3C),
      body: Stack(
        children: [
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          CustomPaint(
            size: Size.infinite,
            painter: CircularOverlayPainter(
              circleColor: _eyesOpen ? AppColors.secondary : Colors.white,
              isComplete: _eyesOpen,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      GestureDetector(
                        onTap: _showHelpDialog,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Prenez un selfie",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Placez votre visage dans le cercle",
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEyeIndicator(_leftEyeOpenProbability),
                const SizedBox(width: 80),
                _buildEyeIndicator(_rightEyeOpenProbability),
              ],
            ),
          ),

          if (_isCameraInitialized)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                onPressed: _isCapturing
                    ? null // Désactivé pendant la capture
                    : _captureEyes, // Toujours activé sinon
                icon: const Icon(Icons.camera, size: 20),
                label: const Text(
                  "Prendre la photo",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          if (_isCapturing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Capture en cours...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEyeIndicator(double openProbability) {
    final isOpen = openProbability > 0.4;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isOpen ? AppColors.secondary : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isOpen ? AppColors.secondary : Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.visibility,
          color: isOpen ? AppColors.secondary : Colors.white.withOpacity(0.5),
          size: 24,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Conseils",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "1. Placez votre visage dans le cercle.\n"
          "2. Le bouton est toujours actif.\n"
          "3. Vous pouvez prendre la photo à tout moment.",
          style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularOverlayPainter extends CustomPainter {
  final Color circleColor;
  final bool isComplete;

  CircularOverlayPainter({required this.circleColor, required this.isComplete});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.saveLayer(null, Paint());

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    canvas.drawCircle(center, radius, Paint()..blendMode = BlendMode.clear);

    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, circlePaint);

    if (isComplete) {
      final progressPaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius + 8, progressPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
