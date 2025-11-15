import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/biometric/presentation/selfie_capture.dart';

class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({Key? key}) : super(key: key);

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  XFile? _capturedDocument;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    await _controller.initialize();

    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized) return;

    try {
      final XFile picture = await _controller.takePicture();
      setState(() {
        _capturedDocument = picture;
      });

      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/document.jpg');
      await picture.saveTo(file.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelfieCaptureScreen(documentImage: file),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors de la capture");
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
        title: const Text('1. Scanne ta pièce d\'identité'),
        actions: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Front side',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _takePicture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Scan document', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}