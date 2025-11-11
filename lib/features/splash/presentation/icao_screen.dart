import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/splash/presentation/icao_result.dart';

class IcaoScreen extends StatefulWidget {
  final CameraDescription camera;

  const IcaoScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<IcaoScreen> createState() => _IcaoScreenState();
}

class _IcaoScreenState extends State<IcaoScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isProcessing = false;
  String _warningMessage = 'Prenez une photo conforme aux normes ICAO';
  bool _faceDetected = false;
  Face? _currentFace;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _startFaceDetection();
        })
        .catchError((Object e) {
          debugPrint('Erreur caméra: $e');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur caméra : $e')));
            Navigator.of(context).pop();
          }
        });
  }

  void _startFaceDetection() {
    _controller.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final inputImage = _convertToInputImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);

          if (mounted) {
            setState(() {
              if (faces.isEmpty) {
                _faceDetected = false;
                _currentFace = null;
              } else if (faces.length > 1) {
                _faceDetected = false;
                _currentFace = null;
              } else {
                final face = faces.first;
                _currentFace = face;

                final headEulerAngleY = face.headEulerAngleY ?? 0;
                final headEulerAngleZ = face.headEulerAngleZ ?? 0;

                if (headEulerAngleY.abs() > 10 || headEulerAngleZ.abs() > 10) {
                  _faceDetected = false;
                } else {
                  _faceDetected = true;
                }
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Erreur détection: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      InputImageRotation rotation;
      if (Platform.isIOS) {
        rotation =
            InputImageRotationValue.fromRawValue(
              widget.camera.sensorOrientation,
            ) ??
            InputImageRotation.rotation0deg;
      } else {
        rotation = _getRotationFromSensor(widget.camera.sensorOrientation);
      }

      final allBytes = <int>[];
      for (final plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      final bytes = Uint8List.fromList(allBytes);

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Erreur conversion image: $e');
      return null;
    }
  }

  InputImageRotation _getRotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _takePicture() async {
    try {
      await _controller.stopImageStream();
      final image = await _controller.takePicture();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            imagePath: image.path,
            detectedFace: _currentFace,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur prise photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Photo ICAO', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Prenez une photo conforme aux normes ICAO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),
                      CustomPaint(
                        size: Size(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                        ),
                        painter: FaceCircleOverlayPainter(
                          faceDetected: _faceDetected,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera, size: 20),
                    label: const Text(
                      'Prendre la photo',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class FaceCircleOverlayPainter extends CustomPainter {
  final bool faceDetected;

  FaceCircleOverlayPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width * 0.4;
    final Offset center = Offset(size.width / 2, size.height / 2.5);

    final Paint overlayPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);
    canvas.restore();

    final Paint circlePaint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, circlePaint);
  }

  @override
  bool shouldRepaint(FaceCircleOverlayPainter oldDelegate) {
    return oldDelegate.faceDetected != faceDetected;
  }
}

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  final Face? detectedFace;

  const ProcessingScreen({Key? key, required this.imagePath, this.detectedFace})
    : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => IcaoResult(
              imagePath: widget.imagePath,
              detectedFace: widget.detectedFace,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.file(
                File(widget.imagePath),
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Traitement en cours...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final String imagePath;
  final Face? detectedFace;

  const ResultsScreen({Key? key, required this.imagePath, this.detectedFace})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Résultats', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
