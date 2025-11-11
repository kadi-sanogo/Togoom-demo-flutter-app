import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/verification/language_service.dart';

class FootprintsCaptureTwo extends StatefulWidget {
  const FootprintsCaptureTwo({super.key});

  @override
  State<FootprintsCaptureTwo> createState() => _FootprintsCaptureTwoState();
}

class _FootprintsCaptureTwoState extends State<FootprintsCaptureTwo> {
  final lang = LanguageService();
  CameraController? _cameraController;
  bool _showCamera = false;
  bool _isCameraInitialized = false;

  // États de détection
  DetectionState _detectionState = DetectionState.waiting;
  int _detectionProgress = 0;
  Timer? _detectionTimer;
  String _errorMessage = '';

  List<bool> _fingersDetected = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Erreur caméra : $e");
    }
  }

  void _openCamera() {
    if (!_isCameraInitialized || _showCamera) return;

    setState(() {
      _showCamera = true;
      _detectionState = DetectionState.detecting;
      _detectionProgress = 0;
      _fingersDetected = [false, false, false, false];
      _errorMessage = '';
    });

    _startDetection();
  }

  void _closeCamera() {
    _detectionTimer?.cancel();
    setState(() {
      _showCamera = false;
      _detectionState = DetectionState.waiting;
      _detectionProgress = 0;
      _fingersDetected = [false, false, false, false];
      _errorMessage = '';
    });
  }

  void _startDetection() {
    _detectionTimer?.cancel();

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      if (!_showCamera || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _detectionProgress++;

        if (_detectionProgress == 2) {
          _fingersDetected[0] = true;
        } else if (_detectionProgress == 4) {
          _fingersDetected[1] = true;
        } else if (_detectionProgress == 6) {
          _fingersDetected[2] = true;
        } else if (_detectionProgress == 8) {
          final random = DateTime.now().microsecondsSinceEpoch % 100;

          if (random < 75) {
            _fingersDetected[3] = true;
            _detectionState = DetectionState.success;
            timer.cancel();

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _showCamera) {
                _closeCamera();
                _showSuccessDialog();
              }
            });
          } else {
            _detectionState = DetectionState.error;
            _errorMessage = _getRandomErrorMessage();
            timer.cancel();

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _showCamera) {
                _startDetection();
              }
            });
          }
        }
      });
    });
  }

  String _getRandomErrorMessage() {
    final errors = [
      'Doigts non détectés',
      'Maintenez vos doigts immobiles',
      'Rapprochez vos doigts',
      'Éloignez légèrement vos doigts',
      'Luminosité insuffisante',
    ];
    final index = DateTime.now().microsecondsSinceEpoch % errors.length;
    return errors[index];
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Empreintes capturées !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vos empreintes digitales ont été enregistrées avec succès.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 100,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Créer un cryptographe",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
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
      body: _showCamera && _isCameraInitialized
          ? _buildCameraScreen()
          : _buildInstructionScreen(),
    );
  }

  Widget _buildInstructionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Placez vos 4 doigts devant la caméra',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Index, majeur, annulaire et auriculaire',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Le reste reste identique
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Appuyez pour scanner',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
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

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_cameraController!)),

        Container(color: Colors.black.withOpacity(0.7)),

        Center(
          child: Container(
            width: 300,
            height: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getBorderColor(), width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  if (_detectionState == DetectionState.success)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.green.withOpacity(0.3),
                              Colors.green.withOpacity(0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.fingerprint,
                            size: 120,
                            color: Colors.green.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                _getStatusMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_detectionState == DetectionState.detecting)
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 40, right: 40),
                  child: LinearProgressIndicator(
                    value: _detectionProgress / 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.yellow,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFingerIndicator(int index) {
    final isDetected = _fingersDetected[index];
    final isActive =
        _detectionState == DetectionState.detecting &&
        index <= _detectionProgress ~/ 2;

    return Container(
      width: 50,
      height: 120,
      decoration: BoxDecoration(
        color: isDetected
            ? Colors.green.withOpacity(0.3)
            : isActive
            ? Colors.yellow.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDetected
              ? Colors.green
              : isActive
              ? Colors.yellow
              : Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: isDetected
            ? const Icon(Icons.check, color: Colors.green, size: 30)
            : isActive
            ? const CircularProgressIndicator(
                color: Colors.yellow,
                strokeWidth: 2,
              )
            : null,
      ),
    );
  }

  Color _getBorderColor() {
    switch (_detectionState) {
      case DetectionState.success:
        return Colors.green;
      case DetectionState.error:
        return Colors.red;
      case DetectionState.detecting:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  Color _getStatusColor() {
    switch (_detectionState) {
      case DetectionState.success:
        return Colors.green;
      case DetectionState.error:
        return Colors.red;
      case DetectionState.detecting:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }

  String _getStatusMessage() {
    switch (_detectionState) {
      case DetectionState.success:
        return '✅ Empreintes capturées !';
      case DetectionState.error:
        return '❌ $_errorMessage';
      case DetectionState.detecting:
        return 'Analyse en cours...';
      default:
        return 'Placez vos 4 doigts dans le cadre';
    }
  }
}

enum DetectionState { waiting, detecting, success, error }
