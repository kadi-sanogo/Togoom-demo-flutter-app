import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:togoom/core/theme/app_colors.dart';
import 'package:togoom/features/auth/presentation/home_page.dart';
import 'package:togoom/features/verification/presentation/icao_screen.dart';

const CameraDescription frontCamera = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 0,
);

class IcaoResult extends StatelessWidget {
  final String imagePath;
  final Face? detectedFace;

  const IcaoResult({Key? key, required this.imagePath, this.detectedFace})
    : super(key: key);

  Map<String, dynamic> _calculateICAOMetrics() {
    if (detectedFace == null) {
      return {
        'eyes': 0.51,
        'nose': 0.61,
        'mouth': 0.74,
        'headRoll': -1.00,
        'headPitch': 0.00,
        'headYaw': -1.00,
        'glasses': 0.26,
        'brightness': 0.25,
        'contrast': 0.66,
        'specularity': 0.42,
        'backgroundUniformity': 0.99,
      };
    }

    final face = detectedFace!;
    return {
      'eyes': 0.51,
      'nose': 0.61,
      'mouth': 0.74,
      'headRoll': face.headEulerAngleZ ?? -1.00,
      'headPitch': face.headEulerAngleX ?? 0.00,
      'headYaw': face.headEulerAngleY ?? -1.00,
      'glasses': 0.26,
      'brightness': 0.25,
      'contrast': 0.66,
      'specularity': 0.42,
      'backgroundUniformity': 0.99,
    };
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _calculateICAOMetrics();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        title: const Text(
          'Results',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ICAO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.file(
                            File(imagePath),
                            width: double.infinity,
                            height: 400,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(
                            color: AppColors.secondary,
                            width: 2,
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Remove background',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ICAO REPORT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 15),

            _buildMetricCard(
              icon: Icons.remove_red_eye_outlined,
              title: 'Eyes',
              value: metrics['eyes'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.blur_circular,
              title: 'Nose',
              value: metrics['nose'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.sentiment_satisfied_outlined,
              title: 'Mouth',
              value: metrics['mouth'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              customIcon: Icons.screen_rotation,
              title: 'Head Roll',
              value: metrics['headRoll'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              customIcon: Icons.swap_vert,
              title: 'Head Pitch',
              value: metrics['headPitch'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              customIcon: Icons.swap_horiz,
              title: 'Head Yaw',
              value: metrics['headYaw'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.remove_red_eye_outlined,
              title: 'Glasses',
              value: metrics['glasses'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Brightness',
              value: metrics['brightness'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.contrast,
              title: 'Contrast',
              value: metrics['contrast'].toStringAsFixed(2),
              isValid: true,
            ),
            _buildMetricCard(
              icon: Icons.circle,
              title: 'Specularity in facial region',
              value: '${metrics['specularity'].toStringAsFixed(2)} (too low)',
              isValid: false,
              valueColor: Colors.red,
            ),
            _buildMetricCard(
              icon: Icons.person_outline,
              title: 'Background uniformity',
              value: metrics['backgroundUniformity'].toStringAsFixed(2),
              isValid: true,
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(
                          color: AppColors.secondary,
                          width: 2,
                        ),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Reprendre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Accueil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    IconData? icon,
    IconData? customIcon,
    required String title,
    required String value,
    required bool isValid,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            customIcon ?? icon ?? Icons.info_outline,
            color: Colors.grey.shade700,
            size: 28,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 28,
          ),
        ],
      ),
    );
  }
}
