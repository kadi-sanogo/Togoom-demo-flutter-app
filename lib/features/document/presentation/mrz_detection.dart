import 'dart:isolate';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Classe pour stocker les données extraites de la MRZ
class MrzData {
  final String documentType;
  final String countryCode;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String nationality;
  final String dateOfBirth;
  final String sex;
  final String expirationDate;
  final String rawMrz;
  final bool isValid;

  MrzData({
    required this.documentType,
    required this.countryCode,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.nationality,
    required this.dateOfBirth,
    required this.sex,
    required this.expirationDate,
    required this.rawMrz,
    required this.isValid,
  });

  @override
  String toString() {
    return '''
MRZ Data:
- Type: $documentType
- Pays: $countryCode
- Document N°: $documentNumber
- Nom: $lastName
- Prénom(s): $firstName
- Nationalité: $nationality
- Date de naissance: $dateOfBirth
- Sexe: $sex
- Expiration: $expirationDate
- Valide: $isValid
    ''';
  }
}

class MrzParser {
  static final RegExp _mrzLineRegex = RegExp(r'^[A-Z0-9<]{25,44}$');
  
  static List<String> detectMrzLines(RecognizedText recognizedText, {bool filterPosition = false}) {
    List<String> mrzLines = [];
    List<double> linePositions = [];

    print("=== TEXTE BRUT OCR ===");
    print(recognizedText.text);
    print("======================");

    // Collecter toutes les lignes MRZ candidates avec leur position Y
    List<Map<String, dynamic>> candidates = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String cleanedLine = line.text
            .toUpperCase()
            .replaceAll(' ', '')
            .replaceAll('«', '<')
            .replaceAll('»', '<');

        if (_mrzLineRegex.hasMatch(cleanedLine) && cleanedLine.length >= 28) {
          double yPos = line.boundingBox?.center.dy ?? 0;
          candidates.add({
            'text': cleanedLine,
            'y': yPos,
          });
          print("MRZ candidate: $cleanedLine (y=$yPos, ${cleanedLine.length} chars)");
        }
      }
    }

    // Si on a des candidats, prendre ceux qui sont proches en Y (même zone MRZ)
    if (candidates.isNotEmpty) {
      // Trier par position Y
      candidates.sort((a, b) => (a['y'] as double).compareTo(b['y'] as double));

      // Prendre les lignes consécutives (écart max 100 pixels)
      List<String> consecutiveLines = [candidates.first['text'] as String];
      double lastY = candidates.first['y'] as double;

      for (int i = 1; i < candidates.length; i++) {
        double currentY = candidates[i]['y'] as double;
        if ((currentY - lastY).abs() < 150) { // Lignes proches
          consecutiveLines.add(candidates[i]['text'] as String);
          lastY = currentY;
        }
      }

      mrzLines = consecutiveLines;
    }

    print("Total lignes MRZ: ${mrzLines.length}");
    if (mrzLines.isNotEmpty) {
      print("=== MRZ BRUTE COMPLÈTE ===");
      for (int i = 0; i < mrzLines.length; i++) {
        print("Ligne ${i + 1}: ${mrzLines[i]}");
      }
      print("==========================");
    }
    return mrzLines;
  }

  static MrzData? parseTD1(List<String> lines) {
    if (lines.length < 3) return null;

    try {
      // Line 1: Type(2) + Country(3) + DocNumber(9) + CheckDigit(1) + Optional(15)
      String line1 = lines[0].padRight(30, '<');
      String documentType = line1.substring(0, 2);
      String countryCode = line1.substring(2, 5);
      String documentNumber = _cleanMrzField(line1.substring(5, 14));

      // Line 2: DOB(6) + Check(1) + Sex(1) + Expiry(6) + Check(1) + Nationality(3) + Optional(11) + Check(1)
      String line2 = lines[1].padRight(30, '<');
      String dateOfBirth = _formatDate(line2.substring(0, 6));
      String sex = line2.substring(7, 8);
      String expirationDate = _formatDate(line2.substring(8, 14));
      String nationality = line2.substring(15, 18);

      // Line 3: Name (SURNAME<<FIRSTNAME)
      String line3 = lines[2].padRight(30, '<');
      String fullName = line3;
      List<String> nameParts = fullName.split('<<');
      String lastName = nameParts.isNotEmpty ? _cleanMrzField(nameParts[0]) : '';
      String firstName = nameParts.length > 1 ? nameParts[1].replaceAll('<', ' ').trim() : '';

      bool isValid = documentNumber.isNotEmpty &&
                     dateOfBirth.isNotEmpty &&
                     lastName.isNotEmpty;

      return MrzData(
        documentType: documentType,
        countryCode: countryCode,
        documentNumber: documentNumber,
        firstName: firstName,
        lastName: lastName,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        sex: sex == 'M' ? 'Masculin' : sex == 'F' ? 'Féminin' : 'Autre',
        expirationDate: expirationDate,
        rawMrz: '${lines[0]}\n${lines[1]}\n${lines[2]}',
        isValid: isValid,
      );
    } catch (e) {
      print('Erreur parsing TD1: $e');
      return null;
    }
  }

  static MrzData? parseTD3(List<String> lines) {
    if (lines.length < 2) return null;

    try {
      String line1 = lines[0].padRight(44, '<');
      String documentType = line1.substring(0, 1); 
      String countryCode = line1.substring(2, 5); 
      String fullName = _cleanMrzField(line1.substring(5, 44));
      
      List<String> nameParts = fullName.split('<<');
      String lastName = nameParts.isNotEmpty ? nameParts[0].trim() : '';
      String firstName = nameParts.length > 1 ? nameParts[1].replaceAll('<', ' ').trim() : '';

      String line2 = lines[1].padRight(44, '<');
      String documentNumber = _cleanMrzField(line2.substring(0, 9));
      String nationality = line2.substring(10, 13);
      String dateOfBirth = _formatDate(line2.substring(13, 19));
      String sex = line2.substring(20, 21);
      String expirationDate = _formatDate(line2.substring(21, 27));

      bool isValid = documentNumber.isNotEmpty && 
                     dateOfBirth.isNotEmpty &&
                     lastName.isNotEmpty;

      return MrzData(
        documentType: documentType,
        countryCode: countryCode,
        documentNumber: documentNumber,
        firstName: firstName,
        lastName: lastName,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        sex: sex == 'M' ? 'Masculin' : sex == 'F' ? 'Féminin' : 'Autre',
        expirationDate: expirationDate,
        rawMrz: '${lines[0]}\n${lines[1]}',
        isValid: isValid,
      );
    } catch (e) {
      print('Erreur parsing TD3: $e');
      return null;
    }
  }

  static String _cleanMrzField(String field) {
    return field.replaceAll('<', ' ').trim();
  }

  static String _formatDate(String mrzDate) {
    if (mrzDate.length != 6) return mrzDate;
    
    String year = mrzDate.substring(0, 2);
    String month = mrzDate.substring(2, 4);
    String day = mrzDate.substring(4, 6);
    
    int yearInt = int.tryParse(year) ?? 0;
    String fullYear = yearInt > 30 ? '19$year' : '20$year';
    
    return '$day/$month/$fullYear';
  }

  static MrzData? extractMrzData(RecognizedText recognizedText) {
    List<String> mrzLines = detectMrzLines(recognizedText);

    if (mrzLines.isEmpty) return null;

    // Trier les lignes par longueur décroissante pour identifier le format
    mrzLines.sort((a, b) => b.length.compareTo(a.length));

    // Détecter le format automatiquement
    String mrzType = _detectMrzType(mrzLines);

    if (mrzType == 'TD3' && mrzLines.length >= 2) {
      // Passeport: 2 lignes de 44 caractères
      List<String> td3Lines = mrzLines.where((l) => l.length >= 40).take(2).toList();
      if (td3Lines.length >= 2) {
        MrzData? td3Data = parseTD3(td3Lines);
        if (td3Data != null && td3Data.isValid) return td3Data;
      }
    }

    if (mrzType == 'TD1' && mrzLines.length >= 3) {
      // Carte d'identité: 3 lignes de 30 caractères
      List<String> td1Lines = mrzLines.where((l) => l.length >= 28 && l.length <= 32).take(3).toList();
      if (td1Lines.length >= 3) {
        MrzData? td1Data = parseTD1(td1Lines);
        if (td1Data != null && td1Data.isValid) return td1Data;
      }
    }

    // Fallback: essayer les deux formats
    if (mrzLines.length >= 2) {
      List<String> longLines = mrzLines.where((l) => l.length >= 40).take(2).toList();
      if (longLines.length >= 2) {
        MrzData? td3Data = parseTD3(longLines);
        if (td3Data != null && td3Data.isValid) return td3Data;
      }
    }

    if (mrzLines.length >= 3) {
      List<String> shortLines = mrzLines.where((l) => l.length >= 28 && l.length <= 35).take(3).toList();
      if (shortLines.length >= 3) {
        MrzData? td1Data = parseTD1(shortLines);
        if (td1Data != null && td1Data.isValid) return td1Data;
      }
    }

    return null;
  }

  static String _detectMrzType(List<String> lines) {
    if (lines.isEmpty) return 'UNKNOWN';

    // Compter les lignes par longueur
    int longLines = lines.where((l) => l.length >= 40).length;
    int shortLines = lines.where((l) => l.length >= 28 && l.length <= 35).length;

    // Vérifier le premier caractère pour le type de document
    String firstChar = lines.first.isNotEmpty ? lines.first[0] : '';

    // P = Passeport (TD3)
    if (firstChar == 'P' && longLines >= 2) {
      return 'TD3';
    }

    // I, A, C = Carte d'identité ou autre document (TD1)
    if ((firstChar == 'I' || firstChar == 'A' || firstChar == 'C') && shortLines >= 3) {
      return 'TD1';
    }

    // Détection par longueur des lignes
    if (longLines >= 2) {
      return 'TD3';
    }

    if (shortLines >= 3) {
      return 'TD1';
    }

    return 'UNKNOWN';
  }
}

class MrzIsolateConfig {
  final SendPort sendPort;
  final String imagePath;

  MrzIsolateConfig({required this.sendPort, required this.imagePath});
}

/// Fonction isolée pour traiter l'image et extraire la MRZ
Future<void> processMrzInIsolate(MrzIsolateConfig config) async {
  try {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(config.imagePath);
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    MrzData? mrzData = MrzParser.extractMrzData(recognizedText);
    
    config.sendPort.send(mrzData);
    await textRecognizer.close();
  } catch (e) {
    config.sendPort.send(null);
    print('Erreur dans isolate: $e');
  }
}

/// Classe utilitaire pour l'extraction MRZ
class MrzExtractor {
  static Future<MrzData?> extractFromImage(String imagePath) async {
    try {
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      MrzData? mrzData = MrzParser.extractMrzData(recognizedText);

      await textRecognizer.close();
      return mrzData;
    } catch (e) {
      print('Erreur extraction MRZ: $e');
      return null;
    }
  }

  static Future<MrzData?> extractFromRecognizedText(RecognizedText recognizedText) async {
    return MrzParser.extractMrzData(recognizedText);
  }
}