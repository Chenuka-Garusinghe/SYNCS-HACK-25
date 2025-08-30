// ignore: file_names
import 'package:flutter/material.dart';
import 'package:terrago/screens/game_screen.dart';
import 'package:rive/rive.dart' as rive;

class ChooseAvatarScreen extends StatefulWidget {
  const ChooseAvatarScreen({super.key});

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  int? selectedAvatarIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Avatar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Select an avatar to represent you',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 380,
              height: 380,
              child: rive.RiveAnimation.asset(
                'assets/floating-4.riv',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: _buildAvatarOption(
                    index: 0,
                    isSelected: selectedAvatarIndex == 0,
                    onTap: () {
                      setState(() {
                        selectedAvatarIndex = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildAvatarOption(
                    index: 1,
                    isSelected: selectedAvatarIndex == 1,
                    onTap: null, // Disabled
                    isLocked: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Confirm button - always show but enable only when avatar is selected
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAvatarIndex != null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GameScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedAvatarIndex != null
                      ? Colors.green[700]
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required int index,
    required bool isSelected,
    required VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLocked
              ? Colors.grey[300]
              : (isSelected ? Colors.green[700] : Colors.grey[200]),
          border: isSelected
              ? Border.all(color: Colors.green[700]!, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Avatar content
            Center(
              child: index == 0
                  ? const ClipOval(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: rive.RiveAnimation.asset(
                          'assets/floating-4.riv',
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),

            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
