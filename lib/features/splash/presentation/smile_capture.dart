import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SmileVerificationScreen extends StatefulWidget {
  final Function(Uint8List)? onSmileCaptured;

  const SmileVerificationScreen({super.key, this.onSmileCaptured});

  @override
  State<SmileVerificationScreen> createState() =>
      _SmileVerificationScreenState();
}

class _SmileVerificationScreenState extends State<SmileVerificationScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _guidanceMessage = "Placez votre visage dans le cercle";
  bool _faceDetected = false;
  bool _isSmiling = false;
  bool _isProcessing = false;
  double _smileProgress = 0.0;

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
      setState(() {
        _faceDetected = false;
        _isSmiling = false;
        _smileProgress = 0.0;
        _guidanceMessage = "Aucun visage détecté";
      });
      return;
    }

    final face = faces.first;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    // Détection du sourire
    final smilingProbability = face.smilingProbability ?? 0.0;

    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();

      setState(() {
        _faceDetected = true;
        _smileProgress = smilingProbability;
      });

      if (eyeDistance < 80) {
        setState(() {
          _guidanceMessage = "Rapprochez-vous";
          _isSmiling = false;
        });
      } else if (eyeDistance > 150) {
        setState(() {
          _guidanceMessage = "Reculer";
          _isSmiling = false;
        });
      } else if (smilingProbability < 0.4) {
        setState(() {
          _guidanceMessage = "Souriez s'il vous plaît !";
          _isSmiling = false;
        });
      } else if (smilingProbability >= 0.4 && smilingProbability < 0.7) {
        setState(() {
          _guidanceMessage = "Souriez plus grand !";
          _isSmiling = false;
        });
      } else {
        setState(() {
          _guidanceMessage = "Sourire parfait !";
          _isSmiling = true;
        });

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_isSmiling && !_isCapturing) {
            _captureSmile();
          }
        });
      }
    }
  }

  Future<void> _captureSmile() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      await _cameraController?.stopImageStream();

      final XFile picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();

      if (widget.onSmileCaptured != null) {
        widget.onSmileCaptured!(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Sourire capturé avec succès !"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur de capture: $e");
      setState(() => _isCapturing = false);
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
      backgroundColor: const Color(0xFF1A2E45),
      body: Stack(
        children: [
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          CustomPaint(
            size: Size.infinite,
            painter: CircularOverlayPainter(
              circleColor: _isSmiling ? Colors.green : Colors.white,
              smileProgress: _smileProgress,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF1A2E45),
                  child: const Text(
                    "Placez votre visage dans le cercle",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _isSmiling
                        ? Colors.green.withOpacity(0.9)
                        : Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSmiling ? Colors.greenAccent : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _guidanceMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 60),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (_faceDetected)
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _smileProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isSmiling ? Colors.green : Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            top: 60,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: _showHelpDialog,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 28,
                ),
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
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Capturer votre sourire...",
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Conseils de vérification du sourire",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "1. Placez votre visage dans le cercle.\n"
          "2. Regardez directement la caméra.\n"
          "3. Faites un grand sourire naturel.\n"
          "4. Gardez votre sourire immobile.\n"
          "5. La photo sera prise automatiquement.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "J'ai compris !",
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 16,
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
  final double smileProgress;

  CircularOverlayPainter({
    required this.circleColor,
    required this.smileProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    canvas.saveLayer(null, Paint());

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    canvas.drawCircle(center, radius, Paint()..blendMode = BlendMode.clear);

    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, circlePaint);

    if (smileProgress > 0) {
      final progressPaint = Paint()
        ..color = smileProgress >= 0.7 ? Colors.green : Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * smileProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 10),
        -3.14159 / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
