import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:togoom/core/theme/app_colors.dart';

class ResultsScreen extends StatelessWidget {
  final File documentImage;
  final File selfieImage;

  const ResultsScreen({
    Key? key,
    required this.documentImage,
    required this.selfieImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIOMETRIC TRUST FACTORS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Face Match
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Face match', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Row(
                          children: [
                            const Text('Passed', style: TextStyle(color: Colors.green)),
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(documentImage, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selfieImage, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verifies the identity document portrait image against the selfie image.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Genuine Camera
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Genuine camera', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Row(
                          children: [
                            const Text('Passed', style: TextStyle(color: Colors.green)),
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Determines whether the image was created during this onboarding process and on this device.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, ModalRoute.withName('/'));
                    },
                    child: const Text('Try again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Validation réussie !");
                      Navigator.popUntil(context, ModalRoute.withName('/'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}