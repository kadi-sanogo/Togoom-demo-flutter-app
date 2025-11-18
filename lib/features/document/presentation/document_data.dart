import 'package:togoom/features/document/presentation/mrz_detection.dart';

class DocumentData {
  // Images 
  String? rectoImagePath;
  String? versoImagePath;
  String? selfieImagePath;
  String? portrait;               
  String? portraitFromIdCard;     
  String? ghostPortrait;
  String? signature;

  //  Données textuelles (RECTO + VERSE)
  String? documentNumber;
  String? firstName;
  String? lastName;
  String? nationality;
  String? dateOfBirth;
  String? sex;
  String? expiryDate;
  String? issueDate;

  

  // Données verso spécifiques
  String? height;
  String? profession;
  String? placeOfBirth;
  String? can;
  String? securityNumber;

  //  Données MRZ 
  MrzData? mrzData;

  //  Métadonnées
  DateTime? captureDateTime;
  bool isVersoScanned = false;

  //  Constructeur
  DocumentData({
    this.rectoImagePath,
    this.versoImagePath,
    this.selfieImagePath,
    this.portrait,
    this.portraitFromIdCard,
    this.ghostPortrait,
    this.signature,
    this.documentNumber,
    this.firstName,
    this.lastName,
    this.nationality,
    this.dateOfBirth,
    this.sex,
    this.expiryDate,
    this.issueDate,
    this.height,
    this.profession,
    this.placeOfBirth,
    this.can,
    this.securityNumber,
    this.mrzData,
  }) {
    captureDateTime = DateTime.now();
    // Synchroniser les portraits
    this.portraitFromIdCard ??= this.portrait;
    this.portrait ??= this.portraitFromIdCard;
  }

  
  void updateFromRecto({
    String? documentNumber,
    String? firstName,
    String? lastName,
    String? nationality,
    String? dateOfBirth,
    String? sex,
    String? expiryDate,
    String? issueDate,
    String? portrait,
    String? rectoImage,
  }) {
    this.documentNumber = documentNumber;
    this.firstName = firstName;
    this.lastName = lastName;
    this.nationality = nationality;
    this.dateOfBirth = dateOfBirth;
    this.sex = sex;
    this.expiryDate = expiryDate;
    this.issueDate = issueDate;
    this.rectoImagePath = rectoImage;
    this.portrait = portrait;
    this.portraitFromIdCard = portrait;
  }

  void updateFromVerso({
    String? height,
    String? profession,
    String? placeOfBirth,
    String? can,
    String? securityNumber,
    String? ghostPortrait,
    String? signature,
    String? versoImage,
  }) {
    this.height = height;
    this.profession = profession;
    this.placeOfBirth = placeOfBirth;
    this.can = can;
    this.securityNumber = securityNumber;
    this.ghostPortrait = ghostPortrait;
    this.signature = signature;
    this.versoImagePath = versoImage;
    this.isVersoScanned = true;
  }

  //  MRZ helpers
  bool get hasMrzData => mrzData != null && mrzData!.isValid;

  //  Validations 
  bool get hasRequiredPhotos =>
      (portraitFromIdCard != null || portrait != null) && 
      selfieImagePath != null;

  bool get isComplete =>
      documentNumber != null &&
      firstName != null &&
      lastName != null &&
      dateOfBirth != null &&
      hasRequiredPhotos;

 
  String get fullName {
    if (firstName == null && lastName == null) return 'N/A';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      // Images
      'rectoImagePath': rectoImagePath,
      'versoImagePath': versoImagePath,
      'selfieImagePath': selfieImagePath,
      'portrait': portraitFromIdCard,
      'ghostPortrait': ghostPortrait,
      'signature': signature,

      // Données textuelles
      'documentNumber': documentNumber,
      'firstName': firstName,
      'lastName': lastName,
      'nationality': nationality,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'expiryDate': expiryDate,
      'issueDate': issueDate,
      'height': height,
      'profession': profession,
      'placeOfBirth': placeOfBirth,
      'can': can,
      'securityNumber': securityNumber,

      // MRZ
      'mrzRaw': mrzData?.rawMrz,

      // Métadonnées
      'captureDateTime': captureDateTime?.toIso8601String(),
      'isVersoScanned': isVersoScanned,
    };
  }

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    final data = DocumentData(
      rectoImagePath: json['rectoImagePath'],
      versoImagePath: json['versoImagePath'],
      selfieImagePath: json['selfieImagePath'],
      portraitFromIdCard: json['portrait'],
      ghostPortrait: json['ghostPortrait'],
      signature: json['signature'],
      documentNumber: json['documentNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      nationality: json['nationality'],
      dateOfBirth: json['dateOfBirth'],
      sex: json['sex'],
      expiryDate: json['expiryDate'],
      issueDate: json['issueDate'],
      height: json['height'],
      profession: json['profession'],
      placeOfBirth: json['placeOfBirth'],
      can: json['can'],
      securityNumber: json['securityNumber'],
    );

    final mrzRaw = json['mrzRaw'] as String?;
    if (mrzRaw != null) {
      
    }

    data.captureDateTime = json['captureDateTime'] != null
        ? DateTime.parse(json['captureDateTime'])
        : null;

    return data;
  }

  @override
  String toString() {
    return 'DocumentData(name: $fullName, number: $documentNumber, complete: $isComplete, MRZ: ${hasMrzData ? "✓" : "✗"})';
  }
}