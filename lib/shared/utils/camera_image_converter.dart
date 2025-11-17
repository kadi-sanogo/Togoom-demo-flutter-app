import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Utilitaire pour convertir les images de la caméra en InputImage pour ML Kit
class CameraImageConverter {
  /// Convertit une CameraImage en InputImage pour ML Kit
  static InputImage? convertToInputImage(
    CameraImage image,
    CameraController cameraController,
  ) {
    try {
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = _getInputImageRotation(cameraController);

      if (Platform.isAndroid && image.format.group == ImageFormatGroup.nv21) {
        return _convertAndroidImage(image, size, rotation);
      } else if (Platform.isIOS &&
          image.format.group == ImageFormatGroup.bgra8888) {
        return _convertIOSImage(image, size, rotation);
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420Image(image, size, rotation);
      } else {
        debugPrint("Format non supporté : ${image.format.group}");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur conversion image : $e");
      return null;
    }
  }

  /// Convertit une image Android NV21
  static InputImage _convertAndroidImage(
    CameraImage image,
    Size size,
    InputImageRotation rotation,
  ) {
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
  }

  /// Convertit une image iOS BGRA8888
  static InputImage _convertIOSImage(
    CameraImage image,
    Size size,
    InputImageRotation rotation,
  ) {
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

  /// Convertit une image YUV420
  static InputImage _convertYUV420Image(
    CameraImage image,
    Size size,
    InputImageRotation rotation,
  ) {
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

  /// Détermine la rotation de l'image en fonction de l'orientation de l'appareil
  static InputImageRotation _getInputImageRotation(
    CameraController cameraController,
  ) {
    final deviceOrientation = cameraController.value.deviceOrientation;

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
}