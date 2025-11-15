import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:togoom/features/verification/presentation/IDVerificationScreen.dart';
import 'document_data.dart';
import 'package:togoom/core/theme/app_colors.dart';

class OCRResultsPage extends StatelessWidget {
  final DocumentData documentData;

  const OCRResultsPage({Key? key, required this.documentData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Résultats OCR",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (documentData.rectoImagePath != null &&
                documentData.rectoImagePath!.isNotEmpty)
              _buildCapturedImage(
                documentData.rectoImagePath!,
                "Photo de la pièce (Recto)",
                height: 200,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Photo de la pièce",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            if (documentData.versoImagePath != null &&
                documentData.versoImagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCapturedImage(
                  documentData.versoImagePath!,
                  "Photo du Verso",
                  height: 200,
                ),
              ),

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
              "PHOTOS EXTRAITES",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Photo d'identité extraite
                if (documentData.portrait != null) ...[
                  Expanded(
                    child: _buildPhotoSection(
                      documentData.portrait,
                      "Photo d'identité",
                    ),
                  ),
                ],
                if (documentData.signature != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPhotoSection(
                      documentData.signature,
                      "Signature",
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Recommencer",
                      style: TextStyle(color: AppColors.secondary),
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
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImageFromBase64(base64Data, width: 120, height: 120),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImage(String imagePath, String label, {double? height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height ?? 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "Image non disponible",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                "Non extrait",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  Uint8List? _decodeBase64Safe(String? input) {
    if (input == null || input.isEmpty) return null;

    String clean = input.trim();

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
