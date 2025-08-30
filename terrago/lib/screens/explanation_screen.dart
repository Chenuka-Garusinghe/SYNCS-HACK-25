import 'package:flutter/material.dart';
import 'package:terrago/screens/form.dart';
import 'animation_screen.dart';
import '../widgets/feature_item.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About Terrago'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.eco,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            // Title
            const Text(
              'Welcome to Terrago!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Description
            const Text(
              'Terrago is your personal environmental companion that helps you track and improve your environmental impact. '
              'Monitor your carbon footprint, discover sustainable practices, and contribute to a greener future.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Column(
                children: [
                  FeatureItem(
                    icon: Icons.track_changes,
                    text: 'Track your environmental impact',
                  ),
                  SizedBox(height: 15),
                  FeatureItem(
                    icon: Icons.lightbulb,
                    text: 'Discover sustainable practices',
                  ),
                  SizedBox(height: 15),
                  FeatureItem(
                    icon: Icons.analytics,
                    text: 'View detailed analytics',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Start button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const FormScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
