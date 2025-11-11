import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/capture_mrz_two.dart';
import 'package:togoom/features/splash/presentation/document_data.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:image/image.dart' as img; 
import 'package:path_provider/path_provider.dart';

class CaptureMrzOne extends StatefulWidget {
  const CaptureMrzOne({Key? key}) : super(key: key);

  @override
  State<CaptureMrzOne> createState() => _CaptureMrzOneState();
}

class _CaptureMrzOneState extends State<CaptureMrzOne>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Placez votre pièce d'identité dans le cadre";
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isCapturing = false;
  String? _extractedPortraitPath;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

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
          _analyzeDocument(recognizedText);
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
      }

      return null;
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

  void _analyzeDocument(RecognizedText recognizedText) {
    if (_isCapturing) return;

    final fullText = recognizedText.text.toLowerCase();

    final isIdCard = fullText.contains('république') ||
        fullText.contains('republique') ||
        fullText.contains('côte') ||
        fullText.contains('cote') ||
        fullText.contains('ivoire') ||
        fullText.contains('carte nationale') ||
        fullText.contains('identité');

    final hasEssentialFields = fullText.contains(RegExp(r'\d{8,}')) ||
        fullText.contains('nom') ||
        fullText.contains('prénom') ||
        fullText.contains('prenom') ||
        fullText.contains('nationalité') ||
        fullText.contains('naissance');

    if (isIdCard || hasEssentialFields) {
      if (mounted) {
        setState(() {
          _statusMessage = "Document détecté Appuyez sur Capturer";
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
      await Future.delayed(const Duration(milliseconds: 300));
      final XFile imageFile = await _cameraController!.takePicture();

      // Extraire le visage de la photo de la pièce
      await _extractFaceFromIdCard(imageFile.path);

      final data = DocumentData();
      data.rectoImagePath = imageFile.path;
      data.portraitFromIdCard = _extractedPortraitPath ?? imageFile.path;

      if (mounted) {
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CaptureMrzTwo(documentData: data),
          ),
        );
      }
    } catch (e) {
      debugPrint(" Erreur capture : $e");
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _statusMessage = "Erreur de capture. Réessayez.";
        });
        _startDocumentDetection();
      }
    }
  }

  Future<void> _extractFaceFromIdCard(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final boundingBox = face.boundingBox;

        if (boundingBox == null) {
          _extractedPortraitPath = imagePath;
          return;
        }

        // Charger l'image originale
        final originalFile = File(imagePath);
        final originalBytes = await originalFile.readAsBytes();
        final originalImage = img.decodeImage(originalBytes); 

        if (originalImage == null) {
          _extractedPortraitPath = imagePath;
          return;
        }

        // Ajuster les coordonnées
        int left = boundingBox.left.toInt().clamp(0, originalImage.width);
        int top = boundingBox.top.toInt().clamp(0, originalImage.height);
        int right = boundingBox.right.toInt().clamp(0, originalImage.width);
        int bottom = boundingBox.bottom.toInt().clamp(0, originalImage.height);

        int cropWidth = (right - left).clamp(1, originalImage.width);
        int cropHeight = (bottom - top).clamp(1, originalImage.height);

        final croppedImage = img.copyCrop( 
          originalImage,
          x: left,
          y: top,
          width: cropWidth,
          height: cropHeight,
        );

        final tempDir = await getTemporaryDirectory();
        final extractedPath =
            '${tempDir.path}/portrait_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final extractedFile = File(extractedPath);
        await extractedFile.writeAsBytes(img.encodeJpg(croppedImage)); 

        _extractedPortraitPath = extractedPath;
      } else {
        _extractedPortraitPath = imagePath;
      }
    } catch (e) {
      debugPrint("Erreur extraction visage : $e");
      _extractedPortraitPath = imagePath;
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
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
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
                  painter: OverlayPainter(captureSuccess: false),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
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
                      child: Center(
                        child: SizedBox(
                          width: size.width * 0.85,
                          height: size.height * 0.35,
                          child: CustomPaint(
                            painter: ScanFramePainter(isSuccess: false),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20.0),
        color: Colors.black,
        child: ElevatedButton.icon(
          onPressed: _isCapturing ? null : _captureAndProcess,
          icon: const Icon(Icons.camera_alt, size: 26),
          label: const Text(
            'Capturer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
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
    drawCorner(Offset(size.width, 0), Offset(size.width - cornerLength, 0), Offset(size.width, cornerLength));
    drawCorner(Offset(0, size.height), Offset(cornerLength, size.height), Offset(0, size.height - cornerLength));
    drawCorner(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), Offset(size.width, size.height - cornerLength));
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.isSuccess != isSuccess;
}

class OverlayPainter extends CustomPainter {
  final bool captureSuccess;
  OverlayPainter({this.captureSuccess = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final frameWidth = size.width * 0.85;
    final frameHeight = size.height * 0.35;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(left, top, frameWidth, frameHeight))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) => false;
}