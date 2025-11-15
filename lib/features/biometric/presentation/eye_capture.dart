import 'dart:io';
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
  bool _faceDetected = false;
  bool _processingImage = false;

  late FaceDetector _faceDetector;
  int _faceDetectedFrames = 0;
  static const int _requiredFrames = 10;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
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
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraInitialized = true);

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _checkPermissions() async {
    final result = await Permission.camera.request();
    if (!result.isGranted && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingImage || _isCapturing) return;

    _processingImage = true;

    try {
      final InputImage inputImage = _convertToInputImage(image);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        _faceDetectedFrames++;

        if (!_faceDetected && mounted) {
          setState(() => _faceDetected = true);
        }

        if (_faceDetectedFrames >= _requiredFrames && !_isCapturing) {
          await _captureFaceAutomatically();
        }
      } else {
        _faceDetectedFrames = 0;
        if (_faceDetected && mounted) {
          setState(() => _faceDetected = false);
        }
      }
    } catch (e) {
      debugPrint("Erreur détection : $e");
    }

    _processingImage = false;
  }

  InputImage _convertToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final InputImageRotation imageRotation = InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = InputImageFormat.nv21;

    final planeData = image.planes.map((Plane plane) {
      return InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      );
    }).toList();

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  Future<void> _captureFaceAutomatically() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await _cameraController!.stopImageStream();

      await Future.delayed(const Duration(milliseconds: 300));

      final XFile picture = await _cameraController!.takePicture();
      final Uint8List bytes = await picture.readAsBytes();

      if (widget.onEyesCaptured != null) {
        widget.onEyesCaptured!(bytes);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(imagePath: picture.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur capture : $e");

      if (mounted) {
        setState(() => _isCapturing = false);
        _cameraController?.startImageStream(_processCameraImage);
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
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Vérification faciale',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CameraPreview(_cameraController!),

                    CustomPaint(
                      painter: FaceCircleOverlayPainter(
                        faceDetected: _faceDetected,
                      ),
                      size: Size.infinite,
                    ),

                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Text(
                        _faceDetected
                            ? '✓ Visage détecté ! Capture en cours...'
                            : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _faceDetected
                              ? Colors.green
                              : Colors.transparent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (_isCapturing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 20),
                              Text(
                                'Capture en cours...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_faceDetected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 10),
                            Text(
                              'Restez immobile...',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FaceCircleOverlayPainter extends CustomPainter {
  final bool faceDetected;

  FaceCircleOverlayPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width * 0.4;
    final Offset center = Offset(size.width / 2, size.height / 2.5);

    final Paint overlayPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);
    canvas.restore();

    final Paint circlePaint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, circlePaint);

    if (faceDetected) {
      final Paint glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawCircle(center, radius + 5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(FaceCircleOverlayPainter oldDelegate) {
    return oldDelegate.faceDetected != faceDetected;
  }
}

class SuccessScreen extends StatelessWidget {
  final String imagePath;

  const SuccessScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'Vérification réussie !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Votre visage a été capturé avec succès',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 50),

              ClipOval(
                child: Image.file(
                  File(imagePath),
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 50),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
