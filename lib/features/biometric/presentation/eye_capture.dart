import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:togoom/shared/widgets/circular_frame_painter.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/domain/liveness_challenge.dart';
import 'package:togoom/shared/presentation/success_screen.dart';

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

  // Liveness challenges
  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _challengeSuccessFrames = 0;
  static const int _requiredChallengeFrames = 5;
  String _challengeMessage = "";
  bool _allChallengesCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeChallenges();
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

  void _initializeChallenges() {
    final random = Random();
    final allChallenges = LivenessChallenge.values.toList();
    allChallenges.shuffle(random);
    _challenges = allChallenges.take(2).toList();
    _updateChallengeMessage();
  }

  void _updateChallengeMessage() {
    if (_currentChallengeIndex >= _challenges.length) {
      setState(() {
        _allChallengesCompleted = true;
        _challengeMessage = "Challenges complétés";
      });
      return;
    }

    final challenge = _challenges[_currentChallengeIndex];
    String message;

    switch (challenge) {
      case LivenessChallenge.smile:
        message = "Souriez";
        break;
      case LivenessChallenge.turnLeft:
        message = "Tournez la tête à gauche";
        break;
      case LivenessChallenge.turnRight:
        message = "Tournez la tête à droite";
        break;
      case LivenessChallenge.blinkBothEyes:
        message = "Clignez des yeux";
        break;
      case LivenessChallenge.openMouth:
        message = "Ouvrez la bouche";
        break;
      case LivenessChallenge.tiltHeadLeft:
        message = "Penchez la tête à gauche";
        break;
      case LivenessChallenge.tiltHeadRight:
        message = "Penchez la tête à droite";
        break;
      case LivenessChallenge.nodHead:
        message = "Hochet la tête";
        break;
    }

    setState(() {
      _challengeMessage = "Challenge ${_currentChallengeIndex + 1}/${_challenges.length}: $message";
    });
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
        final face = faces.first;

        if (!_faceDetected && mounted) {
          setState(() => _faceDetected = true);
        }

        // Si tous les challenges ne sont pas complétés
        if (!_allChallengesCompleted) {
          final challengeSuccess = _checkChallenge(face);

          if (challengeSuccess) {
            _challengeSuccessFrames++;

            if (_challengeSuccessFrames >= _requiredChallengeFrames) {
              // Challenge réussi
              _currentChallengeIndex++;
              _challengeSuccessFrames = 0;
              _updateChallengeMessage();
            }
          } else {
            _challengeSuccessFrames = 0;
          }
        } else {
          // Tous les challenges complétés, on peut capturer
          _faceDetectedFrames++;

          if (_faceDetectedFrames >= _requiredFrames && !_isCapturing) {
            await _captureFaceAutomatically();
          }
        }
      } else {
        _faceDetectedFrames = 0;
        _challengeSuccessFrames = 0;
        if (_faceDetected && mounted) {
          setState(() => _faceDetected = false);
        }
      }
    } catch (e) {
      debugPrint("Erreur détection : $e");
    }

    _processingImage = false;
  }

  bool _checkChallenge(Face face) {
    if (_currentChallengeIndex >= _challenges.length) return false;

    final challenge = _challenges[_currentChallengeIndex];

    switch (challenge) {
      case LivenessChallenge.smile:
        final smilingProb = face.smilingProbability ?? 0.0;
        debugPrint("Smile probability: $smilingProb");
        return smilingProb > 0.5;

      case LivenessChallenge.turnLeft:
        final headY = face.headEulerAngleY ?? 0.0;
        debugPrint("Head Y angle: $headY");
        return headY > 15.0;

      case LivenessChallenge.turnRight:
        final headY = face.headEulerAngleY ?? 0.0;
        debugPrint("Head Y angle: $headY");
        return headY < -15.0;

      case LivenessChallenge.blinkBothEyes:
        final leftEyeProb = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeProb = face.rightEyeOpenProbability ?? 1.0;
        debugPrint("Left eye: $leftEyeProb, Right eye: $rightEyeProb");
        return leftEyeProb < 0.3 && rightEyeProb < 0.3;

      case LivenessChallenge.openMouth:
        // Approximation basée sur la classification du sourire
        final smilingProb = face.smilingProbability ?? 0.0;
        debugPrint("Mouth open (smile approx): $smilingProb");
        return smilingProb > 0.7;

      case LivenessChallenge.tiltHeadLeft:
        final headZ = face.headEulerAngleZ ?? 0.0;
        debugPrint("Head Z angle (tilt): $headZ");
        return headZ > 15.0;

      case LivenessChallenge.tiltHeadRight:
        final headZ = face.headEulerAngleZ ?? 0.0;
        debugPrint("Head Z angle (tilt): $headZ");
        return headZ < -15.0;

      case LivenessChallenge.nodHead:
        final headX = face.headEulerAngleX ?? 0.0;
        debugPrint("Head X angle (nod): $headX");
        return headX.abs() > 15.0;
    }
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

          // Challenge message
          if (_challengeMessage.isNotEmpty)
            Positioned(
              top: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _allChallengesCompleted
                      ? Colors.green.withOpacity(0.8)
                      : Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _challengeMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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

          // Message de capture finale
          if (_allChallengesCompleted && _faceDetected)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
    );
  }
}

