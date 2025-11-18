import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/capture_mrz_result.dart';
import 'package:togoom/features/document/presentation/document_data.dart';
import 'package:togoom/shared/widgets/circle_border_painter.dart';

class CaptureMrzTwo extends StatefulWidget {
  final DocumentData documentData;

  const CaptureMrzTwo({Key? key, required this.documentData}) : super(key: key);

  @override
  State<CaptureMrzTwo> createState() => _CaptureMrzTwoState();
}

class _CaptureMrzTwoState extends State<CaptureMrzTwo>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) {
        _cameraController?.dispose();
        return;
      }

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Erreur initialisation caméra : $e");
    }
  }

  Future<void> _captureSelfie() async {
    if (_isCapturing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_cameraController?.value.isInitialized == true && mounted) {
        final XFile image = await _cameraController!.takePicture();
        widget.documentData.selfieImagePath = image.path;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CaptureMrzResult(documentData: widget.documentData),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur capture selfie : $e");
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleRadius = size.width * 0.4;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
        ),
      ),
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                SizedBox.expand(child: Container(color: Colors.black)),

                Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: circleRadius * 2,
                      height: circleRadius * 2,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: circleRadius * 2,
                            height: circleRadius * 2 *
                                (_cameraController?.value.aspectRatio ?? 1.0),
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final animatedRadius = circleRadius * _pulseAnimation.value;
                      return CustomPaint(
                        size: Size(animatedRadius * 2, animatedRadius * 2),
                        painter: CircleBorderPainter(
                          color: Colors.white,
                          strokeWidth: 4,
                          radius: animatedRadius,
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Prenez une selfie",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Placez votre visage dans le cercle et appuyez sur Capturer",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(32.0),
        color: Colors.black.withOpacity(0.6),
        child: _isCapturing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ElevatedButton(
                onPressed: _captureSelfie,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Capturer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}

