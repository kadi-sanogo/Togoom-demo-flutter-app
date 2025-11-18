import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togoom/shared/widgets/circular_frame_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class IrisCaptureScreen extends StatefulWidget {
  final Function(Uint8List)? onIrisCaptured;

  const IrisCaptureScreen({super.key, this.onIrisCaptured});

  @override
  State<IrisCaptureScreen> createState() => _IrisCaptureScreenState();
}

class _IrisCaptureScreenState extends State<IrisCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _guidanceMessage = "Position your face in the circle";
  bool _faceDetected = false;
  bool _isProcessing = false;

  // ML Kit Face Detector
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

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
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() => _isCameraInitialized = true);
      _startFaceDetection();
    }
  }

  Future<void> _checkPermissions() async {
    var result = await Permission.camera.request();
    if (!result.isGranted && mounted) {
      Navigator.pop(context);
    }
  }

  void _startFaceDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _isCapturing) return;
      _isProcessing = true;

      try {
        final inputImage = _convertToInputImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);

          if (mounted) {
            _analyzeFaces(faces);
          }
        }
      } catch (e) {
        debugPrint("Erreur détection: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotation.rotation0deg;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      debugPrint("Erreur conversion image: $e");
      return null;
    }
  }

  void _analyzeFaces(List<Face> faces) {
    if (faces.isEmpty) {
      setState(() {
        _faceDetected = false;
        _guidanceMessage = "No face detected";
      });
      return;
    }

    final face = faces.first;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      final eyeDistance = (leftEye.position.x - rightEye.position.x).abs();

      if (eyeDistance < 80) {
        setState(() {
          _guidanceMessage = "Move closer";
          _faceDetected = false;
        });
      } else if (eyeDistance > 150) {
        setState(() {
          _guidanceMessage = "Move back";
          _faceDetected = false;
        });
      } else {
        setState(() {
          _guidanceMessage = "Hold steady...";
          _faceDetected = true;
        });

        // Capture automatique après 1.5s de stabilité
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_faceDetected && !_isCapturing) {
            _captureIris();
          }
        });
      }
    }
  }

  Future<void> _captureIris() async {
    if (_cameraController == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      await _cameraController?.stopImageStream();

      final XFile picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();

      if (widget.onIrisCaptured != null) {
        widget.onIrisCaptured!(bytes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Iris capturé avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context); 
        });
      }
    } catch (e) {
      debugPrint("Erreur de capture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" Capture failed. Please try again.")),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: Stack(
        children: [
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          CustomPaint(
            size: Size.infinite,
            painter: CircularFramePainter(
              radiusRatio: 0.35,
              overlayColor: Colors.black,
              overlayOpacity: 0.6,
              circleColor: _faceDetected ? Colors.green : Colors.white,
              circleStrokeWidth: 3.0,
              isSuccess: _faceDetected,
              successColor: Colors.green,
              showGlow: false,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "Take a selfie",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(flex: 2), 
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _guidanceMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _faceDetected ? Colors.green : Colors.white70,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.remove_red_eye_outlined,
                size: 50,
                color: _faceDetected ? Colors.green : Colors.white70,
              ),
            ),
          ),

          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Capturing iris...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}