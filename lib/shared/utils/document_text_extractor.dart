import 'package:togoom/features/document/presentation/document_data.dart';

/// Utilitaire pour extraire les données d'une carte d'identité depuis le texte OCR
class DocumentTextExtractor {
  /// Extrait les données du recto d'une carte d'identité ivoirienne
  static void extractRectoData(String text, DocumentData data) {
    final docNumberRegex = RegExp(r'CI\s*(\d{10,})', caseSensitive: false);
    final docMatch = docNumberRegex.firstMatch(text);
    final documentNumber = docMatch?.group(1) ?? "Non détecté";

    final nomRegex = RegExp(
      r'(?:Nom|NOM)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final nomMatch = nomRegex.firstMatch(text);
    final lastName = nomMatch?.group(1)?.trim() ?? "Non détecté";

    final prenomRegex = RegExp(
      r'(?:Prénom|Prenom|PRENOM)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final prenomMatch = prenomRegex.firstMatch(text);
    final firstName = prenomMatch?.group(1)?.trim() ?? "Non détecté";

    final dateRegex = RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b');
    final dates = dateRegex.allMatches(text).map((m) => m.group(1)).toList();
    final dateOfBirth = dates.isNotEmpty ? dates[0] ?? "Non détecté" : "Non détecté";

    final sexe = text.contains(RegExp(r'\bM\b'))
        ? "M"
        : text.contains(RegExp(r'\bF\b'))
            ? "F"
            : "Non détecté";

    data.updateFromRecto(
      documentNumber: documentNumber,
      firstName: firstName,
      lastName: lastName,
      nationality: "Ivoirienne",
      dateOfBirth: dateOfBirth,
      sex: sexe,
      expiryDate: dates.length > 1 ? dates[1] ?? "Non détecté" : "Non détecté",
      issueDate: dates.length > 2 ? dates[2] ?? "Non détecté" : "Non détecté",
      portrait: data.rectoImagePath ?? "",
      rectoImage: data.rectoImagePath ?? "",
    );
  }

  /// Extrait les données du verso d'une carte d'identité ivoirienne
  static void extractVersoData(String text, DocumentData data) {
    final adresseRegex = RegExp(
      r'(?:Adresse|Domicile|ADRESSE|DOMICILE)[:\s]*([A-ZÀ-Ü0-9\s,.-]+)',
      caseSensitive: false,
    );
    final adresseMatch = adresseRegex.firstMatch(text);
    final address = adresseMatch?.group(1)?.trim() ?? "Non détecté";

    final professionRegex = RegExp(
      r'(?:Profession|PROFESSION)[:\s]*([A-ZÀ-Ü\s]+)',
      caseSensitive: false,
    );
    final professionMatch = professionRegex.firstMatch(text);
    final profession = professionMatch?.group(1)?.trim() ?? "Non détecté";

    // Vous pouvez ajouter d'autres champs si nécessaire
    // Pour l'instant, on log seulement ces informations
    print("Adresse extraite : $address");
    print("Profession extraite : $profession");
  }

  /// Détecte si le texte contient des informations d'un recto de carte d'identité
  static bool isRectoDocument(String text) {
    final lowerText = text.toLowerCase();

    final isIdCard = lowerText.contains('république') ||
        lowerText.contains('republique') ||
        lowerText.contains('côte') ||
        lowerText.contains('cote') ||
        lowerText.contains('ivoire');

    final hasEssentialFields = lowerText.contains(RegExp(r'\d{8,}')) ||
        lowerText.contains('nom') ||
        lowerText.contains('prénom') ||
        lowerText.contains('prenom') ||
        lowerText.contains('identité') ||
        lowerText.contains('identite') ||
        lowerText.contains('carte');

    return isIdCard || hasEssentialFields;
  }

  /// Détecte si le texte contient des informations d'un verso de carte d'identité
  static bool isVersoDocument(String text) {
    final lowerText = text.toLowerCase();

    final isIdCard = lowerText.contains('république') ||
        lowerText.contains('republique') ||
        lowerText.contains('côte') ||
        lowerText.contains('cote') ||
        lowerText.contains('ivoire') ||
        lowerText.contains('verso') ||
        lowerText.contains('signature') ||
        lowerText.contains('empreinte') ||
        lowerText.contains('autorité');

    final hasEssentialFields = lowerText.contains(RegExp(r'\d{8,}')) ||
        lowerText.contains('adresse') ||
        lowerText.contains('domicile') ||
        lowerText.contains('profession') ||
        lowerText.contains('né') ||
        lowerText.contains('ne');

    return isIdCard || hasEssentialFields;
  }
}