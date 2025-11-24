import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/face_capture.dart';
import 'package:togoom/features/document/presentation/photo_extractor.dart';
import 'package:togoom/shared/widgets/overlay_painter.dart';
import 'package:togoom/shared/widgets/scan_frame_painter.dart';
import 'package:togoom/shared/utils/camera_image_converter.dart';
import 'package:togoom/shared/utils/document_detector.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Page de capture de pièce d'identité pour la vérification faciale
/// Capture uniquement le recto, extrait le portrait, puis passe à la capture du visage
class FaceVerificationIdCapture extends StatefulWidget {
  const FaceVerificationIdCapture({Key? key}) : super(key: key);

  @override
  State<FaceVerificationIdCapture> createState() => _FaceVerificationIdCaptureState();
}

class _FaceVerificationIdCaptureState extends State<FaceVerificationIdCapture>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Placez votre pièce d'identité dans le cadre";
  late AnimationController _animationController;

  bool _isCapturing = false;
  bool _documentDetected = false;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final DocumentDetector _documentDetector = DocumentDetector(
    requiredDetections: 1,
  );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError("Aucune caméra disponible");
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startDocumentDetection();
      }
    } catch (e) {
      _showError("Erreur caméra : $e");
      debugPrint("Erreur initialisation caméra : $e");
    }
  }

  void _startDocumentDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCapturing) return;
      _isProcessing = true;

      try {
        final inputImage = CameraImageConverter.convertToInputImage(
          image,
          _cameraController!,
        );
        if (inputImage != null) {
          final recognizedText = await _textRecognizer.processImage(inputImage);
          await _analyzeDocument(recognizedText);
        }
      } catch (e) {
        debugPrint("Erreur OCR : $e");
      } finally {
        await Future.delayed(const Duration(milliseconds: 500));
        _isProcessing = false;
      }
    });
  }

  Future<void> _analyzeDocument(RecognizedText recognizedText) async {
    if (_isCapturing) return;

    final result = _documentDetector.analyzeRectoDocument(recognizedText);

    setState(() {
      _documentDetected = result.detected;
      _statusMessage = result.statusMessage;
    });

    if (_documentDetector.canCapture && !_isCapturing) {
      await _captureAndProcess();
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = "Capture en cours...";
    });

    try {
      await _cameraController?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 500));
      final XFile image = await _cameraController!.takePicture();

      debugPrint("Image capturée : ${image.path}");

      // Extraction du portrait
      setState(() {
        _statusMessage = "Extraction du portrait...";
      });

      final photoResult = await PhotoExtractor.extractPortraitFromRecto(image.path);

      if (photoResult?.base64Photo != null) {
        debugPrint("Portrait extrait avec succès");

        if (mounted) {
          // Naviguer vers la capture du visage avec le portrait extrait
          await _cameraController?.dispose();
          _cameraController = null;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FaceCaptureCamera(
                idCardRectoPath: image.path,
                extractedPortraitBase64: photoResult!.base64Photo,
                onFaceCaptured: (String path) {
                  debugPrint("Visage capturé : $path");
                },
              ),
            ),
          );
        }
      } else {
        debugPrint("Impossible d'extraire le portrait");
        if (mounted) {
          _documentDetector.reset();
          setState(() {
            _isCapturing = false;
            _documentDetected = false;
            _statusMessage = "Portrait non détecté. Réessayez.";
          });
          _startDocumentDetection();
        }
      }
    } catch (e) {
      debugPrint("Erreur capture : $e");
      if (mounted) {
        _documentDetector.reset();
        setState(() {
          _isCapturing = false;
          _documentDetected = false;
          _statusMessage = "Erreur de capture. Réessayez.";
        });
        _startDocumentDetection();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const double frameWidthRatio = 0.95;
    const double frameHeightRatio = 0.28;
    final double frameWidth = size.width * frameWidthRatio;
    final double frameHeight = size.height * frameHeightRatio;

    const double statusPadding = 24.0;
    const double bottomPaddingRatio = 0.11;

    final double topOffset = 0;
    final double availableHeight = size.height - topOffset;
    final double bottomPadding = size.height * bottomPaddingRatio;
    final double centerSpace = availableHeight - bottomPadding;

    final double frameTop = topOffset + (centerSpace - frameHeight) / 2;
    final double frameLeft = (size.width - frameWidth) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Vérification faciale",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              "Étape 1/2 - Pièce d'identité",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_cameraController!)),

                Positioned.fill(
                  child: CustomPaint(
                    size: Size(size.width, size.height),
                    painter: OverlayPainter(
                      captureSuccess: _documentDetected,
                      frameRect: Rect.fromLTWH(
                        frameLeft,
                        frameTop,
                        frameWidth,
                        frameHeight,
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(statusPadding),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _documentDetected
                                ? Colors.green.withOpacity(0.8)
                                : Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: frameWidth,
                      height: frameHeight,
                      child: CustomPaint(
                        painter: ScanFramePainter(
                          isSuccess: _documentDetected,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}