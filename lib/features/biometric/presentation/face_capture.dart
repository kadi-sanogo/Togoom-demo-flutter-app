import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/photo_extractor.dart';
import 'package:togoom/features/verification/presentation/face_verify.dart';
import 'package:togoom/shared/widgets/circular_frame_painter.dart';

class FaceCaptureCamera extends StatefulWidget {
  final Function(String)? onFaceCaptured;
  final String? idCardRectoPath;
  final String? extractedPortraitBase64;

  FaceCaptureCamera({
    super.key,
    this.onFaceCaptured,
    this.idCardRectoPath,
    this.extractedPortraitBase64,
  });

  @override
  State<FaceCaptureCamera> createState() => _FaceCaptureCameraState();
}

class _FaceCaptureCameraState extends State<FaceCaptureCamera> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _faceDetected = false;
  bool _processingImage = false;

  late FaceDetector _faceDetector;
  int _faceDetectedFrames = 0;
  static const int _requiredFrames = 5;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
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
      frontCamera,
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
  final String selfiePath = picture.path;

  if (widget.onFaceCaptured != null) {
    widget.onFaceCaptured!(selfiePath);
  }

  // If an ID card recto path is provided, extract the portrait before navigating.
  final extractionResult = widget.idCardRectoPath != null
      ? await PhotoExtractor.extractPortraitFromRecto(
          widget.idCardRectoPath!,
        )
      : null;

  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationSuccessPage(
          selfieImagePath: selfiePath,
          extractedPortraitBase64: extractionResult?.base64Photo, 
          extractedPortraitPath: extractionResult?.savedFilePath, 
        ),
      ),
    );
  }
}
    catch (e, st) {
      debugPrint('Error capturing face: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
        try {
          _cameraController?.startImageStream(_processCameraImage);
        } catch (_) {
        }
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
                Container(
                  width: 406,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInstructionItem(
                        iconAsset: 'assets/icons/svg/four-finger-02.svg',
                        text: 'Vous ne portez pas de chapeau',
                      ),
                      const SizedBox(height: 20),
                      _buildInstructionItem(
                        iconAsset: 'assets/icons/svg/glasses.svg',
                        text: 'Vous ne portez pas de lunettes de soleil.',
                      ),
                      const SizedBox(height: 20),
                      _buildInstructionItem(
                        iconAsset: 'assets/icons/svg/sun-03.svg',
                        text: "Vous êtes dans une lumière vive",
                      ),
                      const SizedBox(height: 20),
                      _buildInstructionItem(
                        iconAsset: 'assets/icons/svg/happy-01.svg',
                        text:
                            "Vous regardez directement l'objectif de la caméra du téléphone.",
                      ),
                    ],
                  ),
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
        if (iconAsset.isNotEmpty)
          SvgPicture.asset(iconAsset, width: 24, height: 24)
        else
          const Icon(Icons.info_outline, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                height: 1.4,
              ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vérification faciale',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Positionnez votre visage dans le cercle',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          centerTitle: true,
        ),
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

          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: CircularFramePainter(
                  radiusRatio: 0.4,
                  centerOffset: Offset(
                    constraints.maxWidth / 2,
                    constraints.maxHeight / 2.5,
                  ),
                  overlayColor: Colors.black,
                  overlayOpacity: 0.54,
                  circleColor: Colors.white,
                  circleStrokeWidth: 4.0,
                  isSuccess: _faceDetected,
                  successColor: Colors.green,
                  showGlow: true,
                  glowRadius: 5.0,
                  glowStrokeWidth: 8.0,
                ),
                size: Size.infinite,
              );
            },
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

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                const SizedBox(height: 10),

                const Text(
                  'La photo sera prise automatiquement',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
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

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  final dynamic detectedFace;

  const ProcessingScreen({Key? key, required this.imagePath, this.detectedFace})
    : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.file(
                File(widget.imagePath),
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Traitement en cours...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
