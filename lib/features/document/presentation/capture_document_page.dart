import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/photo_extractor.dart';
import 'package:togoom/features/document/presentation/piece_result.dart';
import 'package:togoom/shared/widgets/overlay_painter.dart';
import 'package:togoom/shared/widgets/scan_frame_painter.dart';
import 'package:togoom/shared/utils/camera_image_converter.dart';
import 'package:togoom/shared/utils/document_detector.dart';
import 'package:togoom/shared/utils/document_text_extractor.dart';
import 'document_data.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum DocumentSide { recto, verso }

class CaptureDocumentPage extends StatefulWidget {
  final DocumentSide side;
  final DocumentData? documentData;

  const CaptureDocumentPage({
    Key? key,
    required this.side,
    this.documentData,
  }) : super(key: key);

  @override
  State<CaptureDocumentPage> createState() => _CaptureDocumentPageState();
}

// Alias pour compatibilité
class CaptureRectoPage extends StatelessWidget {
  const CaptureRectoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CaptureDocumentPage(side: DocumentSide.recto);
  }
}

class CaptureVersoPage extends StatelessWidget {
  final DocumentData documentData;
  const CaptureVersoPage({Key? key, required this.documentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CaptureDocumentPage(side: DocumentSide.verso, documentData: documentData);
  }
}

class _CaptureDocumentPageState extends State<CaptureDocumentPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  late String _statusMessage;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isCapturing = false;
  bool _documentDetected = false;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final DocumentDetector _documentDetector = DocumentDetector(
    requiredDetections: 1,
  );

  bool get _isRecto => widget.side == DocumentSide.recto;

  String get _title => _isRecto ? "Scanner le recto" : "Scanner le verso";

  String get _initialMessage => _isRecto
      ? "Placez votre pièce d'identité dans le cadre"
      : "Placez le verso de votre pièce d'identité dans le cadre";

  @override
  void initState() {
    super.initState();
    _statusMessage = _initialMessage;

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

    final result = _isRecto
        ? _documentDetector.analyzeRectoDocument(recognizedText)
        : _documentDetector.analyzeVersoDocument(recognizedText);

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

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (_isRecto) {
        await _processRectoCapture(image, recognizedText);
      } else {
        await _processVersoCapture(image, recognizedText);
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

  Future<void> _processRectoCapture(XFile image, RecognizedText recognizedText) async {
    final data = DocumentData();
    data.rectoImagePath = image.path;

    DocumentTextExtractor.extractRectoData(recognizedText.text, data);

    debugPrint("Extraction de la photo d'identité...");
    final photoResult = await PhotoExtractor.extractPortraitFromRecto(image.path);
    data.portrait = photoResult?.base64Photo;

    if (data.portrait != null) {
      debugPrint("Photo d'identité extraite avec succès");
    } else {
      debugPrint("Impossible d'extraire la photo d'identité");
    }

    debugPrint("Données extraites : ${data.toString()}");

    if (mounted) {
      _showVersoDialog(data);
    }
  }

  Future<void> _processVersoCapture(XFile image, RecognizedText recognizedText) async {
    final data = widget.documentData!;
    data.versoImagePath = image.path;

    DocumentTextExtractor.extractVersoData(recognizedText.text, data);

    debugPrint("Verso capturé : ${image.path}");
    debugPrint("Données verso extraites");

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OCRResultsPage(documentData: data),
        ),
      );
    }
  }

  void _showVersoDialog(DocumentData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sync, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Tournez le document de l'autre côté",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.blue.shade600,
                                size: 32,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 8,
                                    margin: const EdgeInsets.only(
                                      right: 8,
                                      bottom: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    height: 8,
                                    margin: const EdgeInsets.only(
                                      right: 16,
                                      bottom: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Container(
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      borderRadius: BorderRadius.circular(2),
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
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final parentContext = navigator.context;

                      navigator.pop();

                      await _cameraController?.dispose();
                      _cameraController = null;

                      await Future.delayed(const Duration(milliseconds: 300));

                      if (mounted && parentContext.mounted) {
                        Navigator.of(parentContext).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => CaptureDocumentPage(
                              side: DocumentSide.verso,
                              documentData: data,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final parentContext = navigator.context;

                    navigator.pop();

                    await _cameraController?.dispose();
                    _cameraController = null;

                    await Future.delayed(const Duration(milliseconds: 300));

                    if (mounted && parentContext.mounted) {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              OCRResultsPage(documentData: data),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        title: Text(
          _title,
          style: const TextStyle(color: Colors.white),
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

                // Indicateur de chargement pour verso
                if (!_isRecto && _documentDetected && !_isCapturing)
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