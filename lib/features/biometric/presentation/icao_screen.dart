import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/icao_result.dart';

class IcaoScreen extends StatefulWidget {
  final CameraDescription camera;

  const IcaoScreen({Key? key, required this.camera}) : super(key: key);
  @override
  State<IcaoScreen> createState() => _IcaoScreenState();
}

class _IcaoScreenState extends State<IcaoScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _faceDetected = false;
  bool _processingImage = false;
  int _faceDetectedFrames = 0;
  static const int _requiredFrames = 10;

  late FaceDetector _faceDetector;
  Face? _currentFace;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
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
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraInitialized = true);

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _checkPermissions() async {
    final result = await Permission.camera.request();
    if (!result.isGranted) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_processingImage || _isCapturing) return;

    _processingImage = true;

    try {
      final InputImage inputImage = _convertToInputImage(image);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        _currentFace = faces.first;
        _faceDetectedFrames++;

        if (!_faceDetected && mounted) {
          setState(() => _faceDetected = true);
        }

        if (_faceDetectedFrames >= _requiredFrames && !_isCapturing) {
          await _captureFaceAutomatically();
        }
      } else {
        _currentFace = null;
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
    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(
          _cameraController!.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

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
      final path = picture.path;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => IcaoResult(
              imagePath: path,
              detectedFace: _currentFace, 
            ),
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

  void _showInstructionPopup2() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Conditions pour réussir la capture",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInstructionItem(
                  iconAsset: 'assets/icons/svg/four-finger-02.svg',
                  text: 'Vous ne portez pas de chapeau',
                ),
                const SizedBox(height: 15),
                _buildInstructionItem(
                  iconAsset: 'assets/icons/svg/glasses.svg',
                  text: 'Vous ne portez pas de lunettes de soleil.',
                ),
                const SizedBox(height: 15),
                _buildInstructionItem(
                  iconAsset: 'assets/icons/svg/sun-03.svg',
                  text: "Vous êtes dans une lumière vive",
                ),
                const SizedBox(height: 15),
                _buildInstructionItem(
                  iconAsset: 'assets/icons/svg/happy-01.svg',
                  text: "Vous regardez directement l'objectif de la caméra.",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "D'accord",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionItem({
    required String iconAsset,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(iconAsset, width: 24, height: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Photo ICAO',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 4),
            Text(
              'Prenez une photo conforme aux normes ICAO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          CustomPaint(
            painter: FaceCircleOverlayPainter(
              faceDetected: _faceDetected,
            ),
            size: Size.infinite,
          ),
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 25,
            right: 25,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primary,
              onPressed: _showInstructionPopup2,
              child: const Icon(Icons.help_outline, color: Colors.white),
            ),
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
