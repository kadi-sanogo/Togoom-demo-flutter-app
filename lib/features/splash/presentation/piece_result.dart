import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:togoom/features/splash/presentation/IDVerificationScreen.dart';
import 'document_data.dart';

class OCRResultsPage extends StatelessWidget {
  final DocumentData documentData;

  const OCRResultsPage({Key? key, required this.documentData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Résultats OCR"),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (documentData.portrait != null)
              _buildImageFromBase64(documentData.portrait, height: 200),

            const SizedBox(height: 16),
            const Text(
              "Côte d'Ivoire, Identity Card",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            const Text(
              "INFORMATIONS PERSONNELLES",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildField("Prénoms", documentData.firstName),
            _buildField("Nom", documentData.lastName),
            _buildField("Date de naissance", documentData.dateOfBirth),
            _buildField("Sexe", documentData.sex),

            const SizedBox(height: 24),

            const Text(
              "INFORMATIONS DOCUMENT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildField("Numéro de pièce", documentData.documentNumber),
            _buildField("Date d'expiration", documentData.expiryDate),
            _buildField("Type de document", "Carte d'identité"),
            _buildField("Date de délivrance", documentData.issueDate),
            _buildField("Nationalité", documentData.nationality),

            const SizedBox(height: 24),

            const Text(
              "INFORMATIONS SUPPLÉMENTAIRES",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildField("Taille", documentData.height),
            _buildField("Profession", documentData.profession),
            _buildField("Lieu de naissance", documentData.placeOfBirth),
            _buildField("CAN", documentData.can),
            _buildField("Numéro de sécurité", documentData.securityNumber),

            const SizedBox(height: 24),

            const Text(
              "PHOTOS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                if (documentData.portrait != null) ...[
                  Expanded(
                    child: _buildPhotoSection(documentData.portrait, "Photo"),
                  ),
                ],
                if (documentData.signature != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPhotoSection(documentData.signature, "Signature"),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Recommencer",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const DocumentScanScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Continuer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Text(
              value ?? "–",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String? base64Data, String label) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildImageFromBase64(base64Data, width: 100, height: 100),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(
    String? base64Data, {
    double? width,
    double? height,
  }) {
    final bytes = _decodeBase64Safe(base64Data);
    if (bytes == null) {
      return Container(
        width: width ?? 100,
        height: height ?? 100,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          size: 32,
          color: Colors.grey,
        ),
      );
    }
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error, size: 32, color: Colors.red),
      ),
    );
  }

  Uint8List? _decodeBase64Safe(String? input) {
    if (input == null || input.isEmpty) return null;

    String clean = input.trim();

    // Support data URL
    if (clean.startsWith('data:image')) {
      final parts = clean.split(',');
      if (parts.length < 2) return null;
      clean = parts[1];
    }

    clean = clean.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

    try {
      return convert.base64Decode(clean);
    } catch (e) {
      return null;
    }
  }
}