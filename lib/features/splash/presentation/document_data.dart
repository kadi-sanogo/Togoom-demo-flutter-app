class DocumentData {
  String? rectoImagePath;         
  String? portrait;                
  String? portraitFromIdCard;     

  String? selfieImagePath;        

  String? versoImagePath;
  String? ghostPortrait;
  String? signature;

  // DONNÉES TEXTUELLES (RECTO) 
  String? documentNumber;
  String? firstName;
  String? lastName;
  String? nationality;
  String? dateOfBirth;
  String? sex;
  String? expiryDate;
  String? issueDate;

  //  DONNÉES TEXTUELLES (VERSO)
  String? height;
  String? profession;
  String? placeOfBirth;
  String? can;
  String? securityNumber;

  // MÉTADONNÉES 
  DateTime? captureDateTime;
  bool isVersoScanned = false;

  //  CONSTRUCTEUR 
  DocumentData({
    this.rectoImagePath,
    this.portrait,               
    this.portraitFromIdCard,     
    this.selfieImagePath,
    this.versoImagePath,
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
  }) {
    captureDateTime = DateTime.now();
    portraitFromIdCard ??= portrait;
    portrait ??= portraitFromIdCard;
  }

  // MÉTHODES DE MISE À JOUR 
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

  //VALIDATIONS 
  bool get hasRequiredPhotos =>
      (portraitFromIdCard != null || portrait != null) && 
      selfieImagePath != null;

  bool get isComplete =>
      documentNumber != null &&
      firstName != null &&
      lastName != null &&
      dateOfBirth != null &&
      hasRequiredPhotos;

  // UTILITAIRES
  String get fullName {
    if (firstName == null && lastName == null) return 'N/A';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  //SÉRIALISATION 
  Map<String, dynamic> toJson() {
    return {
      'documentNumber': documentNumber,
      'firstName': firstName,
      'lastName': lastName,
      'nationality': nationality,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'expiryDate': expiryDate,
      'issueDate': issueDate,
      'portrait': portraitFromIdCard, 
      'rectoImagePath': rectoImagePath,
      'selfieImagePath': selfieImagePath,
      'height': height,
      'profession': profession,
      'placeOfBirth': placeOfBirth,
      'can': can,
      'securityNumber': securityNumber,
      'ghostPortrait': ghostPortrait,
      'signature': signature,
      'versoImagePath': versoImagePath,
      'captureDateTime': captureDateTime?.toIso8601String(),
      'isVersoScanned': isVersoScanned,
    };
  }

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    final data = DocumentData(
      documentNumber: json['documentNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      nationality: json['nationality'],
      dateOfBirth: json['dateOfBirth'],
      sex: json['sex'],
      expiryDate: json['expiryDate'],
      issueDate: json['issueDate'],
      portraitFromIdCard: json['portrait'],
      rectoImagePath: json['rectoImagePath'],
      selfieImagePath: json['selfieImagePath'],
      height: json['height'],
      profession: json['profession'],
      placeOfBirth: json['placeOfBirth'],
      can: json['can'],
      securityNumber: json['securityNumber'],
      ghostPortrait: json['ghostPortrait'],
      signature: json['signature'],
      versoImagePath: json['versoImagePath'],
    );
    data.captureDateTime = json['captureDateTime'] != null
        ? DateTime.parse(json['captureDateTime'])
        : null;
    return data;
  }

  @override
  String toString() {
    return 'DocumentData(name: $fullName, number: $documentNumber, complete: $isComplete)';
  }
}