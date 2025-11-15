import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/piece_result.dart';
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
  int _detectionCount = 0;
  static const int _requiredDetections = 3;

  final TextRecognizer _textRecognizer = TextRecognizer();

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
        final inputImage = _convertToInputImage(image);
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

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = _getInputImageRotation();

      if (Platform.isAndroid && image.format.group == ImageFormatGroup.nv21) {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final inputImageMetadata = InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
      } else if (Platform.isIOS &&
          image.format.group == ImageFormatGroup.bgra8888) {
        final plane = image.planes[0];
        final bytes = plane.bytes;

        final inputImageMetadata = InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        );

        return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final inputImageMetadata = InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
      } else {
        debugPrint("Format non supporté : ${image.format.group}");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur conversion image : $e");
      return null;
    }
  }

  InputImageRotation _getInputImageRotation() {
    if (_cameraController == null) return InputImageRotation.rotation0deg;

    final deviceOrientation = _cameraController!.value.deviceOrientation;

    if (Platform.isAndroid) {
      switch (deviceOrientation) {
        case DeviceOrientation.portraitUp:
          return InputImageRotation.rotation90deg;
        case DeviceOrientation.landscapeLeft:
          return InputImageRotation.rotation0deg;
        case DeviceOrientation.portraitDown:
          return InputImageRotation.rotation270deg;
        case DeviceOrientation.landscapeRight:
          return InputImageRotation.rotation180deg;
        default:
          return InputImageRotation.rotation90deg;
      }
    } else {
      switch (deviceOrientation) {
        case DeviceOrientation.portraitUp:
          return InputImageRotation.rotation0deg;
        case DeviceOrientation.landscapeLeft:
          return InputImageRotation.rotation270deg;
        case DeviceOrientation.portraitDown:
          return InputImageRotation.rotation180deg;
        case DeviceOrientation.landscapeRight:
          return InputImageRotation.rotation90deg;
        default:
          return InputImageRotation.rotation0deg;
      }
    }
  }

  Future<void> _analyzeDocument(RecognizedText recognizedText) async {
    if (_isCapturing) return;

    final fullText = recognizedText.text.toLowerCase();

    final isIdCard = fullText.contains('république') ||
        fullText.contains('republique') ||
        fullText.contains('côte') ||
        fullText.contains('cote') ||
        fullText.contains('ivoire') ||
        fullText.contains('verso') ||
        fullText.contains('signature') ||
        fullText.contains('empreinte') ||
        fullText.contains('autorité');

    final hasEssentialFields = fullText.contains(RegExp(r'\d{8,}')) ||
        fullText.contains('adresse') ||
        fullText.contains('domicile') ||
        fullText.contains('profession') ||
        fullText.contains('né') ||
        fullText.contains('ne');

    if (isIdCard || hasEssentialFields) {
      _detectionCount++;

      if (!_documentDetected) {
        setState(() {
          _documentDetected = true;
          _statusMessage = "Document détecté ✓ Capture...";
        });
      }

      if (_detectionCount >= _requiredDetections && !_isCapturing) {
        await _captureAndProcess();
      }
    } else {
      if (_detectionCount > 0) {
        _detectionCount = 0;
        setState(() {
          _documentDetected = false;
          _statusMessage = "Placez le verso de votre pièce d'identité dans le cadre";
        });
      }
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

      _extractVersoDataFromText(recognizedText.text, widget.documentData);

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
        setState(() {
          _isCapturing = false;
          _detectionCount = 0;
          _documentDetected = false;
          _statusMessage = "Erreur de capture. Réessayez.";
        });
        _startDocumentDetection();
      }
    }
  }

  void _extractVersoDataFromText(String text, DocumentData data) {
    final adresseRegex = RegExp(
      r'(?:Adresse|Domicile|ADRESSE|DOMICILE)[:\s]*([A-ZÀ-Ü0-9\s,.-]+)',
      caseSensitive: false,
    );
    final adresseMatch = adresseRegex.firstMatch(text);
    final address = adresseMatch?.group(1)?.trim() ?? "Non détecté";

    final professionRegex = RegExp(
      r'(?:Profession|PROFESSION)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final professionMatch = professionRegex.firstMatch(text);
    final profession = professionMatch?.group(1)?.trim() ?? "Non détecté";

    debugPrint("Adresse extraite : $address");
    debugPrint("Profession extraite : $profession");
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
                    screenSize: size,
                  ),
                ),

                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
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
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: size.height * 0.10),
                        child: Center(
                          child: SizedBox(
                            width: size.width * 0.85,
                            height: size.height * 0.32,
                            child: CustomPaint(
                              painter: ScanFramePainter(
                                isSuccess: _documentDetected,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

class ScanFramePainter extends CustomPainter {
  final bool isSuccess;

  ScanFramePainter({this.isSuccess = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSuccess ? Colors.green : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;

    void drawCorner(Offset start, Offset end1, Offset end2) {
      canvas.drawLine(start, end1, paint);
      canvas.drawLine(start, end2, paint);
    }

    drawCorner(Offset(0, 0), Offset(cornerLength, 0), Offset(0, cornerLength));
    drawCorner(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      Offset(size.width, cornerLength),
    );
    drawCorner(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      Offset(0, size.height - cornerLength),
    );
    drawCorner(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height - cornerLength),
    );

    if (isSuccess) {
      final glow = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawRect(Offset.zero & size, glow);
    }
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}

class OverlayPainter extends CustomPainter {
  final bool captureSuccess;
  final Size screenSize;

  OverlayPainter({
    required this.captureSuccess,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.85;
    final frameHeight = size.height * 0.35;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Haut
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, top),
      paint,
    );
    // Bas
    canvas.drawRect(
      Rect.fromLTWH(0, top + frameHeight, size.width, size.height - (top + frameHeight)),
      paint,
    );
    // Gauche
    canvas.drawRect(
      Rect.fromLTWH(0, top, left, frameHeight),
      paint,
    );
    // Droite
    canvas.drawRect(
      Rect.fromLTWH(left + frameWidth, top, size.width - (left + frameWidth), frameHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) => 
    oldDelegate.captureSuccess != captureSuccess;
}
