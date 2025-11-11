import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/features/splash/presentation/face_verify.dart';

class FaceCaptureCamera extends StatefulWidget {
  final Function(String)? onFaceCaptured;

  const FaceCaptureCamera({super.key, this.onFaceCaptured});

  @override
  State<FaceCaptureCamera> createState() => _FaceCaptureCameraState();
}

class _FaceCaptureCameraState extends State<FaceCaptureCamera> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _checkPermissions();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  Future<void> _checkPermissions() async {
    final result = await Permission.camera.request();
    if (!result.isGranted && mounted) Navigator.pop(context);
  }

  Future<void> _captureFace() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final XFile picture = await _cameraController!.takePicture();
      final path = picture.path;
      final faceBytes = await picture.readAsBytes();

      if (widget.onFaceCaptured != null) {
        widget.onFaceCaptured!(path);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationSuccessPage(
              faceImage: faceBytes,
              imagePath: path,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur capture : $e");
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Prévisualisation caméra
          if (_isCameraInitialized)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 🔵 Cercle de guidage (toujours visible)
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),

          // Titre
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: const Text(
              "Positionne ton visage dans le cercle",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20.0),
        color: const Color(0xFF0D1B2A),
        child: ElevatedButton.icon(
          onPressed: _isCapturing ? null : _captureFace,
          icon: const Icon(Icons.camera_alt, size: 24, color: Colors.white),
          label: const Text(
            'Prendre la photo',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
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
