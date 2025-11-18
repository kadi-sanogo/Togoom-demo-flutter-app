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
  
  static List<String> detectMrzLines(RecognizedText recognizedText) {
    List<String> mrzLines = [];
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String cleanedLine = line.text
            .toUpperCase()
            .replaceAll(' ', '')
            .replaceAll('«', '<')
            .replaceAll('»', '<')
            .replaceAll('O', '0'); 
        
        if (_mrzLineRegex.hasMatch(cleanedLine) && cleanedLine.length >= 28) {
          mrzLines.add(cleanedLine);
        }
      }
    }
    
    return mrzLines;
  }

  static MrzData? parseTD1(List<String> lines) {
    if (lines.length < 3) return null;

    try {
      String line1 = lines[0].padRight(30, '<');
      String documentType = line1.substring(0, 2); 
      String countryCode = line1.substring(2, 5); 
      String lastName = _cleanMrzField(line1.substring(5, 30));

      String line2 = lines[1].padRight(30, '<');
      String documentNumber = _cleanMrzField(line2.substring(0, 9));
      String nationality = line2.substring(10, 13);
      String dateOfBirth = _formatDate(line2.substring(13, 19));
      String sex = line2.substring(20, 21);
      String expirationDate = _formatDate(line2.substring(21, 27));

      String line3 = lines[2].padRight(30, '<');
      String firstName = _cleanMrzField(line3);

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

    if (mrzLines.length >= 2 && mrzLines[0].length >= 44) {
      MrzData? td3Data = parseTD3(mrzLines.take(2).toList());
      if (td3Data != null && td3Data.isValid) return td3Data;
    }

    if (mrzLines.length >= 3 && mrzLines[0].length >= 28) {
      MrzData? td1Data = parseTD1(mrzLines.take(3).toList());
      if (td1Data != null && td1Data.isValid) return td1Data;
    }

    return null;
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

/// Classe utilitaire pour utiliser l'extraction MRZ avec Isolate
class MrzExtractor {
  static Future<MrzData?> extractFromImage(String imagePath) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      processMrzInIsolate,
      MrzIsolateConfig(sendPort: receivePort.sendPort, imagePath: imagePath),
    );
    
    final result = await receivePort.first;
    return result as MrzData?;
  }

  static Future<MrzData?> extractFromRecognizedText(RecognizedText recognizedText) async {
    return MrzParser.extractMrzData(recognizedText);
  }
}