import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/capture_mrz_result.dart';
import 'package:togoom/features/document/presentation/document_data.dart';
import 'package:togoom/features/document/presentation/mrz_detection.dart';
import 'package:togoom/shared/widgets/overlay_painter.dart';
import 'package:togoom/shared/widgets/mrz_frame_painter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CaptureMrzOne extends StatefulWidget {
  final DocumentData documentData;

  const CaptureMrzOne({Key? key, required this.documentData}) : super(key: key);

  @override
  State<CaptureMrzOne> createState() => _CaptureMrzOneState();
}

class _CaptureMrzOneState extends State<CaptureMrzOne>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Placez le VERSO de votre pièce dans le cadre";
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isCapturing = false;
  bool _mrzDetected = false;
  int _detectionCount = 0;
  static const int _requiredDetections = 1;
  
  MrzData? _detectedMrzData;
  String? _capturedMrzImagePath;

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
        _startMrzDetection();
      }
    } catch (e) {
      _showError("Erreur caméra : $e");
    }
  }

  void _startMrzDetection() {
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
          await _analyzeMrz(recognizedText);
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

  Future<void> _analyzeMrz(RecognizedText recognizedText) async {
    if (_isCapturing) return;

    final mrzData = await MrzExtractor.extractFromRecognizedText(recognizedText);

    if (mrzData != null && mrzData.isValid) {
      _detectionCount++;
      _detectedMrzData = mrzData;

      if (!_mrzDetected) {
        setState(() {
          _mrzDetected = true;
          _statusMessage = "MRZ détectée - Capture en cours...";
        });
      }

      if (_detectionCount >= _requiredDetections && !_isCapturing) {
        await _captureAndProcess();
      }
    } else {
      if (_detectionCount > 0) {
        _detectionCount = 0;
        setState(() {
          _mrzDetected = false;
          _detectedMrzData = null;
          _statusMessage = "Placez le VERSO de votre pièce dans le cadre";
        });
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = "Capture MRZ en cours...";
    });

    try {
      await _cameraController?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 500));

      final XFile imageFile = await _cameraController!.takePicture();

      // Recadrer l'image sur la zone du cadre MRZ
      final croppedPath = await _cropToFrameArea(imageFile.path);
      _capturedMrzImagePath = croppedPath;

      final finalMrzData = await MrzExtractor.extractFromImage(croppedPath);

      if (finalMrzData != null && finalMrzData.isValid) {
        widget.documentData.versoImagePath = imageFile.path;
        widget.documentData.mrzData = finalMrzData;
        
        widget.documentData.documentNumber = finalMrzData.documentNumber;
        widget.documentData.firstName = finalMrzData.firstName;
        widget.documentData.lastName = finalMrzData.lastName;
        widget.documentData.nationality = finalMrzData.nationality;
        widget.documentData.dateOfBirth = finalMrzData.dateOfBirth;
        widget.documentData.sex = finalMrzData.sex;
        widget.documentData.expiryDate = finalMrzData.expirationDate;

        debugPrint("MRZ extraite avec succès : ${finalMrzData.toString()}");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaptureMrzResult(
                documentData: widget.documentData,
                mrzImagePath: _capturedMrzImagePath!,
              ),
            ),
          );
        }
      } else {
        if (_detectedMrzData != null) {
          widget.documentData.versoImagePath = imageFile.path;
          widget.documentData.mrzData = _detectedMrzData;
          
          widget.documentData.documentNumber = _detectedMrzData!.documentNumber;
          widget.documentData.firstName = _detectedMrzData!.firstName;
          widget.documentData.lastName = _detectedMrzData!.lastName;
          widget.documentData.nationality = _detectedMrzData!.nationality;
          widget.documentData.dateOfBirth = _detectedMrzData!.dateOfBirth;
          widget.documentData.sex = _detectedMrzData!.sex;
          widget.documentData.expiryDate = _detectedMrzData!.expirationDate;

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CaptureMrzResult(
                  documentData: widget.documentData,
                  mrzImagePath: _capturedMrzImagePath!,
                ),
              ),
            );
          }
        } else {
          throw Exception("Impossible d'extraire les données MRZ");
        }
      }
    } catch (e) {
      debugPrint("Erreur capture MRZ : $e");
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _detectionCount = 0;
          _mrzDetected = false;
          _statusMessage = "Erreur de capture. Réessayez.";
        });
        _startMrzDetection();
      }
    }
  }

  Future<String> _cropToFrameArea(String imagePath) async {
    try {
      final originalFile = File(imagePath);
      final originalBytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        return imagePath;
      }

      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;

      // Le cadre MRZ est au centre-bas de l'écran
      // Prendre la bande centrale (90% largeur) à ~50% du haut (20% hauteur)
      final cropLeft = (imageWidth * 0.05).toInt();  // 5% de marge de chaque côté
      final cropTop = (imageHeight * 0.45).toInt();  // Commence à 45%
      final cropWidth = (imageWidth * 0.90).toInt(); // 90% de largeur
      final cropHeight = (imageHeight * 0.20).toInt(); // 20% de hauteur

      final safeLeft = cropLeft.clamp(0, imageWidth - 1);
      final safeTop = cropTop.clamp(0, imageHeight - 1);
      final safeWidth = cropWidth.clamp(1, imageWidth - safeLeft);
      final safeHeight = cropHeight.clamp(1, imageHeight - safeTop);

      debugPrint("Image: ${imageWidth}x${imageHeight}");
      debugPrint("Crop: left=$safeLeft, top=$safeTop, w=$safeWidth, h=$safeHeight");

      final croppedImage = img.copyCrop(
        originalImage,
        x: safeLeft,
        y: safeTop,
        width: safeWidth,
        height: safeHeight,
      );

      final tempDir = await getTemporaryDirectory();
      final croppedPath = '${tempDir.path}/mrz_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      debugPrint("Image recadrée : $croppedPath");
      return croppedPath;
    } catch (e) {
      debugPrint("Erreur recadrage : $e");
      return imagePath;
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

    final frameWidth = size.width * 0.90;
    final frameHeight = size.height * 0.15;
    final left = (size.width - frameWidth) / 2;
    final top = size.height * 0.50;
    final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Scanner le VERSO (zone MRZ)",
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
                    captureSuccess: _mrzDetected,
                    frameRect: frameRect,
                  ),
                ),

                Positioned(
                  left: left,
                  top: top,
                  child: SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: CustomPaint(
                      painter: MrzFramePainter(
                        isSuccess: _mrzDetected,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _mrzDetected
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
    );
  }
}




/*import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/capture_mrz_result.dart';
import 'package:togoom/features/document/presentation/capture_mrz_two.dart';
import 'package:togoom/features/document/presentation/document_data.dart';
import 'package:togoom/shared/widgets/overlay_painter.dart';
import 'package:togoom/shared/widgets/mrz_frame_painter.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CaptureMrzOne extends StatefulWidget {
final DocumentData documentData;

  const CaptureMrzOne({Key? key, required this.documentData}) : super(key: key);

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
  bool _documentDetected = false;
  int _detectionCount = 0;
  static const int _requiredDetections = 1;
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

  Future<void> _analyzeDocument(RecognizedText recognizedText) async {
    if (_isCapturing) return;

    final fullText = recognizedText.text.toLowerCase();

    final isIdCard =
        fullText.contains('république') ||
        fullText.contains('republique') ||
        fullText.contains('côte') ||
        fullText.contains('cote') ||
        fullText.contains('ivoire') ||
        fullText.contains('carte nationale') ||
        fullText.contains('identité');

    final hasEssentialFields =
        fullText.contains(RegExp(r'\d{8,}')) ||
        fullText.contains('nom') ||
        fullText.contains('prénom') ||
        fullText.contains('prenom') ||
        fullText.contains('nationalité') ||
        fullText.contains('naissance');

    if (isIdCard || hasEssentialFields) {
      _detectionCount++;

      if (!_documentDetected) {
        setState(() {
          _documentDetected = true;
          _statusMessage = "Document détecté - Capture...";
        });
      }

      // Capture automatique après 3 détections consécutives
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
      final XFile imageFile = await _cameraController!.takePicture();

      await _extractFaceFromIdCard(imageFile.path);

      final data = DocumentData();
      data.rectoImagePath = imageFile.path;
      data.portraitFromIdCard = _extractedPortraitPath ?? imageFile.path;

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CaptureMrzResult(documentData: widget.documentData),
            ),
          );
      }
    } catch (e) {
      debugPrint("Erreur capture : $e");
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

    // Calcul du frameRect pour l'overlay - zone MRZ réaliste
    final frameWidth = size.width * 0.90;
    final frameHeight = size.height * 0.12;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Scanner le recto de votre pièce d'identité",
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
                    frameRect: frameRect,
                  ),
                ),

                Positioned(
                  left: left,
                  top: top,
                  child: SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: CustomPaint(
                      painter: MrzFramePainter(
                        isSuccess: _documentDetected,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 24,
                  left: 24,
                  right: 24,
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
  }*/