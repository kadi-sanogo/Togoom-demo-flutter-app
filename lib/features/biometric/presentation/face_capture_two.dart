import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/shared/services/language_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math';

enum LivenessChallenge {
  smile,
  turnLeft,
  turnRight,
}

class FaceCaptureTwoScreen extends StatefulWidget {
  final Function(String imagePath) onFaceCaptured;

  const FaceCaptureTwoScreen({super.key, required this.onFaceCaptured});

  @override
  State<FaceCaptureTwoScreen> createState() => _FaceCaptureTwoScreenState();
}

class _FaceCaptureTwoScreenState extends State<FaceCaptureTwoScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isInitialized = false;
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

  final lang = LanguageService();

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
    }

    setState(() {
      _challengeMessage = "Challenge ${_currentChallengeIndex + 1}/${_challenges.length}: $message";
    });
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![1], // caméra frontale
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.startImageStream(_processCameraImage);
      }
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
            await _captureFace();
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

    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile photo = await _controller!.takePicture();
      widget.onFaceCaptured(photo.path);
    } catch (e) {
      print("Erreur capture face: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la capture")),
      );
      setState(() {
        _isCapturing = false;
      });
      _controller?.startImageStream(_processCameraImage);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _faceDetected ? Colors.green : AppColors.secondary,
                  width: 4
                ),
              ),
            ),
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

          // Message de capture finale
          if (_allChallengesCompleted && _faceDetected)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
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
    );
  }
}