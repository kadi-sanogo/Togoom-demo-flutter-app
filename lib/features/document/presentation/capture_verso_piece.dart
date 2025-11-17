import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/piece_result.dart';
import 'package:togoom/shared/widgets/overlay_painter.dart';
import 'package:togoom/shared/widgets/scan_frame_painter.dart';
import 'package:togoom/shared/utils/camera_image_converter.dart';
import 'package:togoom/shared/utils/document_detector.dart';
import 'package:togoom/shared/utils/document_text_extractor.dart';
import 'document_data.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CaptureVersoPage extends StatefulWidget {
  final DocumentData documentData;
  const CaptureVersoPage({Key? key, required this.documentData})
      : super(key: key);

  @override
  State<CaptureVersoPage> createState() => _CaptureVersoPageState();
}

class _CaptureVersoPageState extends State<CaptureVersoPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Placez le verso de votre pièce d'identité dans le cadre";
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isCapturing = false;
  bool _documentDetected = false;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final DocumentDetector _documentDetector = DocumentDetector(requiredDetections: 3);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
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
        final inputImage = CameraImageConverter.convertToInputImage(image, _cameraController!);
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

    final result = _documentDetector.analyzeVersoDocument(recognizedText);

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
      _statusMessage = "📸 Capture en cours...";
    });

    try {
      await _cameraController?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 500));
      final XFile image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      widget.documentData.versoImagePath = image.path;

      DocumentTextExtractor.extractVersoData(recognizedText.text, widget.documentData);

      debugPrint("✓ Verso capturé : ${image.path}");
      debugPrint("✓ Données verso extraites");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OCRResultsPage(documentData: widget.documentData),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur capture verso : $e");
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

    // Dimensions du cadre
    const double frameWidthRatio = 0.95;
    const double frameHeightRatio = 0.28;
    final double frameWidth = size.width * frameWidthRatio;
    final double frameHeight = size.height * frameHeightRatio;

    // Calcul de la position exacte du cadre
    const double statusPadding = 24.0;
    const double statusContainerHeight = 60.0; // Approximation hauteur du message
    const double bottomPaddingRatio = 0.11;

    final double topOffset = 0; //statusPadding + statusContainerHeight;
    final double availableHeight = size.height - topOffset;
    final double bottomPadding = size.height * bottomPaddingRatio;
    final double centerSpace = availableHeight - bottomPadding;

    // Position verticale du cadre (centré dans l'espace disponible)
    final double frameTop = topOffset + (centerSpace - frameHeight) / 2;
    final double frameLeft = (size.width - frameWidth) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Scanner le verso",
          style: TextStyle(color: Colors.white),
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
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),

                CustomPaint(
                  size: Size(size.width, size.height),
                  painter: OverlayPainter(
                    captureSuccess: _documentDetected,
                    frameRect: Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
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
                  child: Expanded(
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
                ),

                if (_documentDetected && !_isCapturing)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 6,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
