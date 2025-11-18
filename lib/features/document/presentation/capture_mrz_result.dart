import 'dart:io';
import 'package:flutter/material.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/document/presentation/document_data.dart';

class CaptureMrzResult extends StatelessWidget {
  final DocumentData documentData;
  final String mrzImagePath;

  const CaptureMrzResult({
    Key? key,
    required this.documentData,
    required this.mrzImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mrzData = documentData.mrzData;
    final hasMrz = mrzData != null && mrzData.isValid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          "Résultat MRZ",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: hasMrz
          ? _buildSuccessView(context, mrzData)
          : _buildErrorView(context),
    );
  }

  Widget _buildSuccessView(BuildContext context, mrzData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Image de la zone MRZ capturée
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Zone MRZ capturée",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(mrzImagePath),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informations extraites
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Informations extraites",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  icon: Icons.badge,
                  title: "Type de document",
                  value: _getDocumentType(mrzData.documentType),
                ),
                _buildInfoCard(
                  icon: Icons.flag,
                  title: "Pays émetteur",
                  value: "${mrzData.countryCode} (${_getCountryName(mrzData.countryCode)})",
                ),
                _buildInfoCard(
                  icon: Icons.numbers,
                  title: "Numéro de document",
                  value: mrzData.documentNumber,
                ),
                _buildInfoCard(
                  icon: Icons.person,
                  title: "Nom",
                  value: mrzData.lastName,
                ),
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: "Prénom(s)",
                  value: mrzData.firstName,
                ),
                _buildInfoCard(
                  icon: Icons.public,
                  title: "Nationalité",
                  value: "${mrzData.nationality} (${_getCountryName(mrzData.nationality)})",
                ),
                _buildInfoCard(
                  icon: Icons.cake,
                  title: "Date de naissance",
                  value: mrzData.dateOfBirth,
                ),
                _buildInfoCard(
                  icon: Icons.wc,
                  title: "Sexe",
                  value: mrzData.sex,
                ),
                _buildInfoCard(
                  icon: Icons.event_available,
                  title: "Date d'expiration",
                  value: mrzData.expirationDate,
                ),

                const SizedBox(height: 20),

                // MRZ brute
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            "MRZ brute",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          mrzData.rawMrz,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Colors.greenAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.refresh),
                    label: Text("Rescanner"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                    
                    },
                    icon: Icon(Icons.check),
                    label: Text("Continuer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              "Erreur d'extraction MRZ",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Impossible de lire les données MRZ.\nVeuillez réessayer avec une meilleure qualité d'image.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.refresh),
              label: Text("Réessayer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "N/A" : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDocumentType(String code) {
    switch (code.toUpperCase()) {
      case 'P':
      case 'PA':
      case 'PC':
        return "Passeport";
      case 'ID':
      case 'I':
        return "Carte d'identité";
      case 'AC':
        return "Carte de crédit";
      case 'V':
      case 'VA':
      case 'VB':
        return "Visa";
      default:
        return code;
    }
  }

  String _getCountryName(String code) {
    final countries = {
      'CIV': 'Côte d\'Ivoire',
      'FRA': 'France',
      'USA': 'États-Unis',
      'GBR': 'Royaume-Uni',
      'DEU': 'Allemagne',
      'ESP': 'Espagne',
      'ITA': 'Italie',
      'BEL': 'Belgique',
      'CHE': 'Suisse',
      'CAN': 'Canada',
      'SEN': 'Sénégal',
      'MLI': 'Mali',
      'BFA': 'Burkina Faso',
      'NER': 'Niger',
      'TGO': 'Togo',
      'GHA': 'Ghana',
      'NGA': 'Nigeria',
      'BEN': 'Bénin',
    };
    return countries[code.toUpperCase()] ?? code;
  }
}