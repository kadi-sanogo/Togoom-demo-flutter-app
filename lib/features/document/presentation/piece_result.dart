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
    debugPrint(" État de la photo d'identité (portrait):");
    debugPrint("   portrait == null ? ${documentData.portrait == null}");
    if (documentData.portrait != null) {
      final snippet = documentData.portrait!.substring(
        0,
        documentData.portrait!.length > 60 ? 60 : documentData.portrait!.length,
      );
      debugPrint("   Extrait base64 (ou autre) : $snippet...");
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Résultats OCR",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            if (documentData.rectoImagePath?.isNotEmpty == true)
              _buildCapturedImage(
                documentData.rectoImagePath!,
                "Photo de la pièce (Recto)",
                height: 210,
              )
            else
              _buildImagePlaceholder("Photo de la pièce", height: 210),

            const SizedBox(height: 8),

            if (documentData.versoImagePath?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCapturedImage(
                  documentData.versoImagePath!,
                  "Photo du Verso",
                  height: 200,
                ),
              ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Côte d'Ivoire, Identity Card",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader("INFORMATIONS PERSONNELLES"),
            _buildField("Prénom(s)", documentData.firstName, Icons.person),
            _buildField("Nom", documentData.lastName, Icons.badge),
            _buildField("Date de naissance", documentData.dateOfBirth, Icons.cake),
            _buildField("Sexe", documentData.sex, Icons.wc),

            const SizedBox(height: 24),

            _buildSectionHeader("INFORMATIONS DOCUMENT"),
            _buildField("Numéro de pièce", documentData.documentNumber, Icons.numbers),
            _buildField("Date d'expiration", documentData.expiryDate, Icons.event),
            _buildField("Type de document", "Carte d'identité", Icons.credit_card),
            _buildField("Date d'émission", documentData.issueDate, Icons.calendar_today),
            _buildField("Nationalité", documentData.nationality, Icons.flag),

            const SizedBox(height: 24),

            // INFORMATIONS SUPPLÉMENTAIRES 
            _buildSectionHeader("INFORMATIONS SUPPLÉMENTAIRES"),
            _buildField("Taille", documentData.height, Icons.height),
            _buildField("Profession", documentData.profession, Icons.work),
            _buildField("Lieu de naissance", documentData.placeOfBirth, Icons.location_on),
            _buildField("CAN", documentData.can, Icons.qr_code),
            _buildField("Numéro de sécurité", documentData.securityNumber, Icons.security),

            const SizedBox(height: 24),

            // PHOTOS EXTRAITES
            _buildSectionHeader("PHOTOS EXTRAITES"),
            _buildPhotoSection(
              documentData.portrait,
              "Photo d'identité",
            ),

            const SizedBox(height: 32),

            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.secondary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Recommencer",
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                     
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continuer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildField(String label, String? value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? "–",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
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
                        Text("Image non disponible", style: TextStyle(color: Colors.grey)),
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

  Widget _buildImagePlaceholder(String label, {double? height}) {
    return Container(
      width: double.infinity,
      height: height ?? 210,
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
            Text("Photo de la pièce", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String? base64Data, String label) {
    final isDataValid = base64Data != null && base64Data.isNotEmpty;
    final bytes = _decodeBase64Safe(base64Data);

    if (isDataValid && (base64Data!.startsWith('/') || base64Data.contains('storage'))) {
      debugPrint(" ERREUR CRITIQUE : portrait semble être un chemin de fichier, pas du base64 !");
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bytes != null ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bytes != null ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bytes != null ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: bytes != null ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  bytes != null ? "Photo extraite" : "Aucune photo extraite",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bytes != null ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImageFromBase64(base64Data, width: 200, height: 200),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          if (bytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Taille: ${(bytes.length / 1024).toStringAsFixed(1)} KB",
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String? base64Data, {double? width, double? height}) {
    final bytes = _decodeBase64Safe(base64Data);

    if (bytes == null) {
      return Container(
        width: width ?? 100,
        height: height ?? 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                "Photo non\nextraite",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
             
            ],
          ),
        ),
      );
    }

    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(" Erreur affichage Image.memory: $error");
        return Container(
          color: Colors.red[100],
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        );
      },
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

    if (clean.isEmpty) {
      debugPrint(" Chaîne base64 vide après nettoyage");
      return null;
    }

    try {
      final decoded = convert.base64Decode(clean);
      return decoded;
    } catch (e) {
      debugPrint(" Erreur décodage base64: $e");
      return null;
    }
  }
}
