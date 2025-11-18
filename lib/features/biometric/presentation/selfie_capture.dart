import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/results_screen.dart';

class SelfieCaptureScreen extends StatefulWidget {
  final File documentImage;

  const SelfieCaptureScreen({Key? key, required this.documentImage}) : super(key: key);

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  XFile? _capturedSelfie;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.where((cam) => cam.lensDirection == CameraLensDirection.front).first;

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller.initialize();

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _takeSelfie() async {
    if (!_isCameraInitialized) return;

    try {
      final XFile selfie = await _controller.takePicture();
      setState(() {
        _capturedSelfie = selfie;
      });

      // Sauvegarde temporaire
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/selfie.jpg');
      await selfie.saveTo(file.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            documentImage: widget.documentImage,
            selfieImage: file,
          ),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors de la capture du selfie");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Take a selfie'),
        actions: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Stay still...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takeSelfie,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}