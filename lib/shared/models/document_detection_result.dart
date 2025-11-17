/// Résultat de la détection de document
class DocumentDetectionResult {
  final bool detected;
  final int detectionCount;
  final String statusMessage;

  DocumentDetectionResult({
    required this.detected,
    required this.detectionCount,
    required this.statusMessage,
  });
}