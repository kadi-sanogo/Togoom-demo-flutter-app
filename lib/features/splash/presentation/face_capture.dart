import 'dart:convert';
import 'dart:typed_data';

import 'package:airsnap_face_flutter_plugin/airsnap_face_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/face_verify.dart';

class FaceCaptureCamera extends StatefulWidget {
  final Function(String) onFaceCaptured;

  const FaceCaptureCamera({super.key, required this.onFaceCaptured});

  @override
  State<FaceCaptureCamera> createState() => _FaceCameraCameraState();
}

class _FaceCameraCameraState extends State<FaceCaptureCamera> {
  bool _isVerified = false;
  String? _capturedImagePath;
  AirsnapFaceFlutterPlugin _plugin = AirsnapFaceFlutterPlugin();
  Uint8List? _faceImage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  Future<void> _checkPermissions() async {
    var result = await Permission.camera.request();
    if (!result.isGranted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 120,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Créer un cryptographe',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Titre
                  const Text(
                    'Approchez votre visage de la\ncaméra',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Badge "Vérifié" (affiché seulement si vérifié)
                  if (_isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Vérifié',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  InkWell(
                    onTap: () {
                      startCamera();
                    },
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isVerified ? Colors.green : Colors.grey[400]!,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: Center(
                          child: _faceImage == null
                              ? SvgPicture.asset(
                                  'assets/icons/svg/camera-01.svg',
                                  width: 30,
                                  height: 30,
                                  color: Colors.grey[600],
                                )
                              : Image.memory(_faceImage!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton Valider
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isVerified && _capturedImagePath != null
                    ? () {
                        // Naviguer vers la page de vérification réussie
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationSuccessPage(
                              imagePath: _capturedImagePath!,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Valider',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startCamera() async {
    final compressionConfig = {
      "compressBy": "COMPRESS_BY_TARGET_SIZE",
      "compressionRate": 80,
      "targetSizeInKbs": 1024,
    };
    final params = {
      "useBackCamera": false,
      "autoCapture": true,
      "isoEnabled": true,
      "isCompress": true,
      "compressionConfig": compressionConfig,
      "captureMode": 0,
    };
    final jsonParams = jsonEncode(params);

    final result = await AirsnapFaceFlutterPlugin().startFaceCapture(
      jsonParams,
    );
    if (result != null) {
      final decoded = json.decode(result);

      final base64CompressedImage = decoded['faceimage'] ?? "";
      final base64OriginalImage = decoded['originalimage'] ?? "";

      final compressedImage = base64Decode(base64CompressedImage);
      final originalImage = base64Decode(base64OriginalImage);

      final decodedImage = await decodeImageFromList(compressedImage);

      setState(() {
        _faceImage = compressedImage;
      });
    }
  }
}


/*import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceIDCaptureScreen extends StatefulWidget {
  final Function(String imagePath) onFaceCaptured;
  
  const FaceIDCaptureScreen({
    Key? key,
    required this.onFaceCaptured,
  }) : super(key: key);

  @override
  State<FaceIDCaptureScreen> createState() => _FaceIDCaptureScreenState();
}

class _FaceIDCaptureScreenState extends State<FaceIDCaptureScreen> 
    with SingleTickerProviderStateMixin {
  
  // Controllers et détecteurs
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  
  // Animation controller simplifié
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // États de détection
  bool _isCameraReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFaceDetector();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.1,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur initialisation caméra: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized || 
        _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      
      final XFile photo = await _cameraController!.takePicture();
      
      if (mounted) {
        widget.onFaceCaptured(photo.path);
        // Navigation vers CryptoPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CryptoPage(imagePath: photo.path),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur capture photo: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _manualCapture() {
    _capturePhoto(); // capture immédiate, peu importe la position
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Aperçu caméra
            if (_isCameraReady && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              ),
            
            // Message de chargement
            if (!_isCameraReady)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Initialisation de la caméra...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Overlay Face ID simplifié
            if (_isCameraReady)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: SimpleFaceOverlayPainter(
                        circleColor: Colors.white,
                        pulseScale: _pulseAnimation.value,
                        isAligned: true,
                      ),
                    );
                  },
                ),
              ),
            
            // Boutons de contrôle
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton fermer
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  // Bouton capture manuelle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isCapturing ? null : _manualCapture,
                      icon: Icon(
                        Icons.camera_alt,
                        color: _isCapturing ? Colors.grey : Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicateur de capture en cours
            if (_isCapturing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Capture en cours...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}

// Painter simplifié pour l'overlay Face ID
class SimpleFaceOverlayPainter extends CustomPainter {
  final Color circleColor;
  final double pulseScale;
  final bool isAligned;

  SimpleFaceOverlayPainter({
    required this.circleColor,
    required this.pulseScale,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.25;
    final radius = baseRadius * (isAligned ? pulseScale : 1.0);
    
    // Masque sombre avec trou transparent
    final maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: baseRadius))
      ..fillType = PathFillType.evenOdd;
    
    final maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);
    
    canvas.drawPath(maskPath, maskPaint);
    
    // Cercle de guidage principal
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = circleColor;
    
    canvas.drawCircle(center, radius, circlePaint);
  }

  @override
  bool shouldRepaint(SimpleFaceOverlayPainter oldDelegate) {
    return oldDelegate.circleColor != circleColor ||
           oldDelegate.pulseScale != pulseScale ||
           oldDelegate.isAligned != isAligned;
  }
}

// CryptoPage exemple
class CryptoPage extends StatelessWidget {
  final String imagePath;
  const CryptoPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Photo capturée:'),
            const SizedBox(height: 20),
            Image.file(File(imagePath)),
          ],
        ),
      ),
    );
  }
}
*/