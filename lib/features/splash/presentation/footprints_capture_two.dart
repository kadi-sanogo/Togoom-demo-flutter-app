import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_svg/svg.dart';
import 'package:togoom/core/theme/app_colors.dart';

class FootprintsCaptureTwo extends StatefulWidget {
  const FootprintsCaptureTwo({super.key});

  @override
  State<FootprintsCaptureTwo> createState() => _FootprintsCaptureTwoState();
}

class _FootprintsCaptureTwoState extends State<FootprintsCaptureTwo> {
  CameraController? _cameraController;
  bool _showCamera = false;
  bool _isCameraInitialized = false;
  String? _capturedImagePath;
  
  //Lite pour chaque empreinte et d liste pour élémentsd de deg fy hfb 
  List<bool> _fingerprintVerified = [false, false, false, false, false];
  int _currentFingerprintIndex = 0;
  bool _isCapturingFingerprint = false;
  bool _isScanning = false;
  bool _isDetectingFinger = false;
  bool _fingerDetected = false;
  
  // Noms des doigts pour l'affichage
  List<String> _fingerNames = [
    'Pouce',
    'Index', 
    'Majeur',
    'Annulaire',
    'Auriculaire'
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation de la caméra: $e');
    }
  }

  void _openCamera() {
    if (_isCameraInitialized && !_allFingerprintsVerified) {
      setState(() {
        _showCamera = true;
        _isScanning = true;
      });
      // Démarrer le processus de scan automatique après un délai
      _startAutomaticScanning();
    }
  }
// close camer, demarrer 
  void _closeCamera() {
    setState(() {
      _showCamera = false;
      _isScanning = false;
      _isCapturingFingerprint = false;
      _isDetectingFinger = false;
      _fingerDetected = false;
    });
  }

  Future<void> _startAutomaticScanning() async {
    // Attendre 2 secondes avant de commencer le premier scan
    await Future.delayed(const Duration(seconds: 2));
    
    if (!_showCamera) return; // Si la caméra a été fermée, arrêter
    
    _scanNextFingerprint();
  }

  Future<void> _scanNextFingerprint() async {
    if (_currentFingerprintIndex >= _fingerprintVerified.length || !_showCamera) {
      return;
    }

    // Phase 1: Détection du doigt.  phase de detection du doigt . détection du doigt , 

    setState(() {
      _isDetectingFinger = true;
      _fingerDetected = false;
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!_showCamera) return;

    // Vérifier si un objet est connecté ( detetion smiluaion )
    bool fingerFound = await _simulateFingerDetection();
    
    if (!fingerFound) {
      // Aucun objet detecté , 
      setState(() {
        _isDetectingFinger = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (_showCamera) {
        _scanNextFingerprint(); 
      }
      return;
    }

    setState(() {
      _fingerDetected = true;
      _isDetectingFinger = false;
      _isCapturingFingerprint = true;
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!_showCamera) return;

    // Phase 3: Validation de la qualité de l'empreinte
    bool fingerprintValid = await _simulateFingerprintValidation();
    
    if (!fingerprintValid) {
     
      setState(() {
        _isCapturingFingerprint = false;
        _fingerDetected = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_showCamera) {
        _scanNextFingerprint(); // Réessayer
      }
      return;
    }

    // Phase 4: Empreinte validée
    setState(() {
      _fingerprintVerified[_currentFingerprintIndex] = true;
      _currentFingerprintIndex++;
      _isCapturingFingerprint = false;
      _fingerDetected = false;
    });

    // Si toutes les empreintes ne sont pas encore scannées, continuer
    if (_currentFingerprintIndex < _fingerprintVerified.length && _showCamera) {
      await Future.delayed(const Duration(seconds: 1));
      _scanNextFingerprint();
    } else if (_allFingerprintsVerified) {
      await Future.delayed(const Duration(milliseconds: 500));
      _closeCamera();
    }
  }

  // Simulation de la détection de doigt
  Future<bool> _simulateFingerDetection() async {
    // Simuler un délai de traitement d'image
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 85% de chance de détecter un doigt (simulation)
    return DateTime.now().millisecondsSinceEpoch % 100 < 85;
  }

  // Simulation de la validation de l'empreinte
  Future<bool> _simulateFingerprintValidation() async {
    // Simuler l'analyse de la qualité de l'empreinte
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 90% de chance que l'empreinte soit valide (simulation)
    return DateTime.now().millisecondsSinceEpoch % 100 < 90;
  }

  void _onFingerprintTap() {
    if (_currentFingerprintIndex < _fingerprintVerified.length) {
      _openCamera();
    }
  }

  void _validatePhoto() {
    Navigator.pop(context);
  }

  bool get _allFingerprintsVerified {
    return _fingerprintVerified.every((verified) => verified);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 100,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'TOGGOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Créer un cryptographe",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (!_showCamera) ...[
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      _allFingerprintsVerified 
                          ? 'Toutes les empreintes ont été capturées'
                          : 'Placez vos 5 doigts devant la caméra',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Container principal avec les empreintes
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Zone de vérification principale
                          GestureDetector(
                            onTap: _onFingerprintTap,
                            child: Container(
                              width: double.infinity,
                              height: 400,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 280,
                                      height: 350,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF87C5BA),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                      ),
                                      child: _allFingerprintsVerified
                                          ? const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 60,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Toutes les empreintes\nont été capturées',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/svg/three-finger-03.svg",
                                                    width: 45,
                                                    height: 45,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Appuyez pour commencer\nle scan des empreintes',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Badge Vérifié
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _allFingerprintsVerified 
                                            ? Colors.green 
                                            : const Color(0xFF87C5BA),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _allFingerprintsVerified ? 'Terminé' : 'En attente',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Zone des empreintes digitales
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (index) {
                                bool isVerified = _fingerprintVerified[index];
                                bool isCurrent = index == _currentFingerprintIndex && !_allFingerprintsVerified;
                                
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isCurrent 
                                        ? Border.all(
                                            color: const Color(0xFF87C5BA),
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: SvgPicture.asset(
                                    "assets/icons/svg/finger-print-check.svg",
                                    width: 40,
                                    height: 40,
                                    color: isVerified 
                                        ? Colors.green
                                        : isCurrent
                                            ? const Color(0xFF87C5BA)
                                            : Colors.grey[400]!,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton valider ,
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _allFingerprintsVerified ? _validatePhoto : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allFingerprintsVerified 
                              ? AppColors.secondary 
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Valider ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],

          // Interface caméra
          if (_showCamera && _isCameraInitialized) ...[
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: CameraPreview(_cameraController!)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 250,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isCapturingFingerprint 
                                  ? Colors.green 
                                  : _isDetectingFinger
                                      ? Colors.orange
                                      : _fingerDetected
                                          ? Colors.blue
                                          : Colors.white, 
                              width: 3
                            ),
                          ),
                          child: _isDetectingFinger
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.orange,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Détection...',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _fingerDetected
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.fingerprint,
                                              color: Colors.blue,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Doigt détecté!',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _isCapturingFingerprint
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  color: Colors.green,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Capture en cours...',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : null,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 20,
                    child: IconButton(
                      onPressed: _closeCamera,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            _isCapturingFingerprint
                                ? 'Scan en cours...'
                                : 'Placez vos 5 doigts dans le cadre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (_currentFingerprintIndex < _fingerNames.length)
                            Text(
                              _isCapturingFingerprint
                                  ? 'Capture: ${_fingerNames[_currentFingerprintIndex]}'
                                  : 'Prochain: ${_fingerNames[_currentFingerprintIndex]}',
                              style: TextStyle(
                                color: _isCapturingFingerprint 
                                    ? Colors.green 
                                    : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          bool isVerified = _fingerprintVerified[index];
                          bool isCurrent = index == _currentFingerprintIndex;
                          
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isVerified 
                                  ? Colors.green
                                  : isCurrent && _isCapturingFingerprint
                                      ? Colors.orange
                                      : isCurrent
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isVerified 
                                    ? Icons.check
                                    : Icons.fingerprint,
                                color: isVerified 
                                    ? Colors.white
                                    : isCurrent
                                        ? Colors.black
                                        : Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}