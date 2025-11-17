import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/capture_verso_piece.dart';
import 'package:togoom/features/document/presentation/piece_result.dart';
import 'document_data.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CaptureRectoPage extends StatefulWidget {
  const CaptureRectoPage({Key? key}) : super(key: key);

  @override
  State<CaptureRectoPage> createState() => _CaptureRectoPageState();
}

class _CaptureRectoPageState extends State<CaptureRectoPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Placez votre pièce d'identité dans le cadre";
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
        debugPrint(" Format non supporté : ${image.format.group}");
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

    final isIdCard =
        fullText.contains('république') ||
        fullText.contains('republique') ||
        fullText.contains('côte') ||
        fullText.contains('cote') ||
        fullText.contains('ivoire');

    final hasEssentialFields =
        fullText.contains(RegExp(r'\d{8,}')) ||
        fullText.contains('nom') ||
        fullText.contains('prénom') ||
        fullText.contains('prenom') ||
        fullText.contains('identité') ||
        fullText.contains('identite') ||
        fullText.contains('carte');

    if (isIdCard || hasEssentialFields) {
      _detectionCount++;

      if (!_documentDetected) {
        setState(() {
          _documentDetected = true;
          _statusMessage = "Document détecté , Capture...";
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
          _statusMessage = "Placez votre pièce d'identité dans le cadre";
        });
      }
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

      final data = DocumentData();
      data.rectoImagePath = image.path;

      _extractDataFromText(recognizedText.text, data);

      debugPrint(" Données extraites : ${data.toString()}");

      //  popup
      if (mounted) {
        _showVersoDialog(data);
      }
    } catch (e) {
      debugPrint(" Erreur capture : $e");
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CaptureVersoPage(documentData: data),
                        ),
                      );
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OCRResultsPage(documentData: data),
                      ),
                    );
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

  void _extractDataFromText(String text, DocumentData data) {
    final docNumberRegex = RegExp(r'CI\s*(\d{10,})', caseSensitive: false);
    final docMatch = docNumberRegex.firstMatch(text);
    final documentNumber = docMatch?.group(1) ?? "Non détecté";

    final nomRegex = RegExp(
      r'(?:Nom|NOM)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final nomMatch = nomRegex.firstMatch(text);
    final lastName = nomMatch?.group(1)?.trim() ?? "Non détecté";

    final prenomRegex = RegExp(
      r'(?:Prénom|Prenom|PRENOM)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final prenomMatch = prenomRegex.firstMatch(text);
    final firstName = prenomMatch?.group(1)?.trim() ?? "Non détecté";

    final dateRegex = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b');
    final dates = dateRegex.allMatches(text).map((m) => m.group(1)).toList();
    final dateOfBirth = dates.isNotEmpty
        ? dates[0] ?? "Non détecté"
        : "Non détecté";

    final sexe = text.contains(RegExp(r'\bM\b'))
        ? "M"
        : text.contains(RegExp(r'\bF\b'))
        ? "F"
        : "Non détecté";

    data.updateFromRecto(
      documentNumber: documentNumber,
      firstName: firstName,
      lastName: lastName,
      nationality: "Ivoirienne",
      dateOfBirth: dateOfBirth,
      sex: sexe,
      expiryDate: dates.length > 1 ? dates[1] ?? "Non détecté" : "Non détecté",
      issueDate: dates.length > 2 ? dates[2] ?? "Non détecté" : "Non détecté",
      portrait: data.rectoImagePath ?? "",
      rectoImage: data.rectoImagePath ?? "",
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Scanner le recto",
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
                Positioned.fill(child: CameraPreview(_cameraController!)),

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
                           width: size.width * 0.95,
                            height: size.height * 0.28,
                            
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
  

  OverlayPainter({required this.captureSuccess, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.95;
    final frameHeight = size.height * 0.30;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        top + frameHeight,
        size.width,
        size.height - (top + frameHeight),
      ),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(0, top, left, frameHeight), paint);
    canvas.drawRect(
      Rect.fromLTWH(
        left + frameWidth,
        top,
        size.width - (left + frameWidth),
        frameHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.captureSuccess != captureSuccess;
}
