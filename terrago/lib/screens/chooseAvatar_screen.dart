// ignore: file_names
import 'package:flutter/material.dart';

class ChooseAvatarScreen extends StatefulWidget {
  const ChooseAvatarScreen({super.key});

  @override
  State<ChooseAvatarScreen> createState() => _ChooseAvatarScreenState();
}

class _ChooseAvatarScreenState extends State<ChooseAvatarScreen> {
  int? selectedAvatarIndex;
  final List<String> avatars = [
    '👤',
    '👨',
    '👩',
    '👶',
    '👴',
    '👵',
    '🦊',
    '🐱',
    '🐶',
    '🐼',
    '🐨',
    '🐯',
    '🌟',
    '⭐',
    '🌙',
    '☀️',
    '🌈',
    '🎈',
    '🎭',
    '🎨',
    '🎪',
    '🎯',
    '🎲',
    '🎮',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Avatar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select an avatar to represent you',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 avatars per row
                  crossAxisSpacing: 16, // Horizontal spacing between avatars
                  mainAxisSpacing: 16, // Vertical spacing between avatar rows
                  childAspectRatio: 1.0, // Perfect circles
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAvatarIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatarIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.blue : Colors.grey[200],
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          avatars[index],
                          style: TextStyle(
                            fontSize: 32,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            if (selectedAvatarIndex != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle avatar selection
                    Navigator.pop(context, selectedAvatarIndex);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
