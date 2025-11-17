import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:togoom/shared/models/document_detection_result.dart';
import 'package:togoom/shared/utils/document_text_extractor.dart';

/// Gestionnaire de détection de document avec logique de comptage
class DocumentDetector {
  int _detectionCount = 0;
  final int requiredDetections;
  bool _documentDetected = false;

  DocumentDetector({this.requiredDetections = 3});

  /// Analyse le texte reconnu pour détecter un recto de carte d'identité
  DocumentDetectionResult analyzeRectoDocument(RecognizedText recognizedText) {
    final fullText = recognizedText.text;
    final isDocument = DocumentTextExtractor.isRectoDocument(fullText);

    if (isDocument) {
      _detectionCount++;

      if (!_documentDetected) {
        _documentDetected = true;
      }

      if (_detectionCount >= requiredDetections) {
        return DocumentDetectionResult(
          detected: true,
          detectionCount: _detectionCount,
          statusMessage: "Document détecté, Capture...",
        );
      } else {
        return DocumentDetectionResult(
          detected: true,
          detectionCount: _detectionCount,
          statusMessage: "Document détecté ($_detectionCount/$requiredDetections)...",
        );
      }
    } else {
      if (_detectionCount > 0) {
        reset();
      }
      return DocumentDetectionResult(
        detected: false,
        detectionCount: 0,
        statusMessage: "Placez votre pièce d'identité dans le cadre",
      );
    }
  }

  /// Analyse le texte reconnu pour détecter un verso de carte d'identité
  DocumentDetectionResult analyzeVersoDocument(RecognizedText recognizedText) {
    final fullText = recognizedText.text;
    final isDocument = DocumentTextExtractor.isVersoDocument(fullText);

    if (isDocument) {
      _detectionCount++;

      if (!_documentDetected) {
        _documentDetected = true;
      }

      if (_detectionCount >= requiredDetections) {
        return DocumentDetectionResult(
          detected: true,
          detectionCount: _detectionCount,
          statusMessage: "Document détecté ✓ Capture...",
        );
      } else {
        return DocumentDetectionResult(
          detected: true,
          detectionCount: _detectionCount,
          statusMessage: "Document détecté ($_detectionCount/$requiredDetections)...",
        );
      }
    } else {
      if (_detectionCount > 0) {
        reset();
      }
      return DocumentDetectionResult(
        detected: false,
        detectionCount: 0,
        statusMessage: "Placez le verso de votre pièce d'identité dans le cadre",
      );
    }
  }

  /// Vérifie si le document a été suffisamment détecté pour capturer
  bool get canCapture => _detectionCount >= requiredDetections && _documentDetected;

  /// Réinitialise le compteur de détection
  void reset() {
    _detectionCount = 0;
    _documentDetected = false;
  }

  /// Getters
  int get detectionCount => _detectionCount;
  bool get documentDetected => _documentDetected;
}