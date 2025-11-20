import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ExtractedPhotoResult {
  final String base64Photo;
  final String savedFilePath;

  ExtractedPhotoResult({
    required this.base64Photo,
    required this.savedFilePath,
  });
}

class PhotoExtractor {
  static Future<ExtractedPhotoResult?> extractPortraitFromRecto(
    String rectoImagePath,
  ) async {
    try {
      final File imageFile = File(rectoImagePath);

      if (!await imageFile.exists()) {
        debugPrint("Image introuvable");
        return null;
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(imageBytes);

      if (original == null) {
        debugPrint("Impossible de décoder l'image");
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final detectionPath = path.join(tempDir.path, "detect_temp.jpg");

      img.Image detectionImage = original;
      double scaleX = 1.0;
      double scaleY = 1.0;

      if (original.width > 2000) {
        detectionImage = img.copyResize(original, width: 2000);
        scaleX = original.width / detectionImage.width;
        scaleY = original.height / detectionImage.height;
      }

      await File(
        detectionPath,
      ).writeAsBytes(img.encodeJpg(detectionImage, quality: 95));

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.01,
        ),
      );

      final faces = await faceDetector.processImage(
        InputImage.fromFilePath(detectionPath),
      );
      await faceDetector.close();

      if (faces.isEmpty) {
        debugPrint("Aucun visage détecté — extraction annulée");
        return null;
      }

      final Face best = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >
                b.boundingBox.width * b.boundingBox.height
            ? a
            : b,
      );

      debugPrint("Visage détecté");
      final res = await _cropFromBoundingBox(
        original,
        best.boundingBox,
        scaleX,
        scaleY,
      );
      return res;
    } catch (e, s) {
      debugPrint("ERREUR extractPortraitFromRecto: $e\n$s");
      return null;
    }
  }

  static Future<ExtractedPhotoResult?> _cropFromBoundingBox(
    img.Image original,
    Rect box,
    double scaleX,
    double scaleY,
  ) async {
    try {
      double x = box.left * scaleX;
      double y = box.top * scaleY;
      double w = box.width * scaleX;
      double h = box.height * scaleY;

      // Marges autour du visage
      const margin = 0.40;
      final mX = w * margin;
      final mY = h * margin;

      x -= mX;
      y -= mY * 1.4;
      w += mX * 2;
      h += mY * 2;

      const targetRatio = 1.3;
      final currentRatio = h / w;
      if (currentRatio < targetRatio) {
        h = w * targetRatio;
      }

      x = x.clamp(0, original.width - 1);
      y = y.clamp(0, original.height - 1);

      if (x + w > original.width) w = original.width - x;
      if (y + h > original.height) h = original.height - y;

      if (w < 20 || h < 20) {
        debugPrint("Crop trop petit");
        return null;
      }

      img.Image cropped = img.copyCrop(
        original,
        x: x.toInt(),
        y: y.toInt(),
        width: w.toInt(),
        height: h.toInt(),
      );

      cropped = _postProcess(cropped);
      return await _saveAndEncode(cropped);
    } catch (e) {
      debugPrint("erreur cropFromBoundingBox: $e");
      return null;
    }
  }

  static img.Image _postProcess(img.Image imgIn) {
    const int targetWidth = 350;
    final int targetHeight = (imgIn.height * (targetWidth / imgIn.width))
        .toInt();

    img.Image out = img.copyResize(
      imgIn,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    out = img.adjustColor(
      out,
      contrast: 1.12,
      brightness: 1.04,
      saturation: 1.05,
    );

    const List<num> sharpenKernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];
    out = img.convolution(
      out,
      filter: sharpenKernel,
      div: 1,
      offset: 0,
      amount: 1,
    );

    return out;
  }

  static Future<ExtractedPhotoResult?> _saveAndEncode(img.Image image) async {
    try {
      final png = img.encodePng(image);
      final base64 = base64Encode(png);

      final dir = await getApplicationDocumentsDirectory();
      final portraitsDir = Directory(path.join(dir.path, "Portraits"));
      if (!await portraitsDir.exists()) {
        await portraitsDir.create();
      }

      final fp = path.join(
        portraitsDir.path,
        "portrait_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      await File(fp).writeAsBytes(png);

      return ExtractedPhotoResult(base64Photo: base64, savedFilePath: fp);
    } catch (e) {
      debugPrint("save/encode error: $e");
      return null;
    }
  }
}
