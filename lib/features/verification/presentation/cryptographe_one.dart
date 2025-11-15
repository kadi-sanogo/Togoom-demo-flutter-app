import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/verification/presentation/cryptographe_two.dart';
import 'package:togoom/features/biometric/presentation/face_capture.dart';
import 'package:togoom/features/biometric/presentation/face_capture_ICAO.dart';
import 'package:togoom/features/biometric/presentation/footprints_capture.dart';
import 'package:togoom/features/biometric/presentation/footprints_capture_two.dart';
import 'package:togoom/features/verification/language_service.dart';

class CryptoPage extends StatefulWidget {
  const CryptoPage({super.key});

  @override
  State<CryptoPage> createState() => _CryptoGenerationPageState();
}

class _CryptoGenerationPageState extends State<CryptoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referenceController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _isFaceCaptureDone = false;
  bool _isFingerprintCaptureDone = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referenceController.dispose();
    _birthDateController.dispose();
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
              'TOGOOM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Créer un cryptographe',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              const Center(
                                child: Text(
                                  'Génération cryptographique',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Center(
                                child: Text(
                                  'Sécurisation de vos données',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoRow(
                                      icon: Icons.access_time,
                                      text: 'Temps estimé : 1-2 min',
                                    ),
                                    SizedBox(height: 6),
                                    _BulletItem(text: "Remplir le formulaire"),
                                    _BulletItem(text: "Capturer votre visage"),
                                    _BulletItem(
                                      text: "Capturer vos empreintes",
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Nom complet',
                                      hint: 'Ex : Boni Aristide',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDateField(),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'exemple@mail.com',
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildTextField(
                                      controller: _referenceController,
                                      label: 'ID de référencement',
                                      hint: 'Ex : AB1234CD',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              _buildCaptureItem(
                                iconAsset: 'assets/icons/svg/face-id.svg',
                                title: 'Capture visage',
                                isDone: _isFaceCaptureDone,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FaceCaptureCamera(),
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      _isFaceCaptureDone = true;
                                    });
                                  });
                                },
                              ),

                              // Capture empreintes
                              _buildCaptureItem(
                                iconAsset: 'assets/icons/svg/finger-access.svg',
                                title: 'Capture empreintes',
                                isDone: _isFingerprintCaptureDone,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FootprintsCaptureTwo(),
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      _isFingerprintCaptureDone = true;
                                    });
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CryptographeTwo(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Créer le cryptographe',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vos données sont sécurisées et utilisées uniquement pour la vérification.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Champ date
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de naissance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _birthDateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'jj/mm/aaaa',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.black,
              size: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(
                const Duration(days: 6570),
              ), // 18 ans
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _birthDateController.text =
                    "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La date de naissance est obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCaptureItem({
    required String iconAsset,
    required String title,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: SvgPicture.asset(iconAsset, width: 18, height: 18),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        trailing: Icon(
          isDone ? Icons.check_circle : Icons.arrow_forward_ios,
          color: isDone ? Colors.green : AppColors.secondary,
          size: isDone ? 18 : 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
