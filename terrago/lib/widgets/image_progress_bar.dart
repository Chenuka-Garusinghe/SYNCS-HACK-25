import 'package:flutter/material.dart';

class ImageProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final String imagePath;
  final List<double> milestones;
  final double milestoneYOffset;
  final VoidCallback? onMilestoneReached;

  const ImageProgressBar({
    super.key,
    required this.progress,
    required this.height,
    required this.imagePath,
    this.milestones = const [0.0, 0.25, 0.5, 0.75, 1.0],
    this.milestoneYOffset = 0.0,
    this.onMilestoneReached,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base progress bar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E6),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: const LinearGradient(
                  colors: [Color(0xFF37B24D), Color(0xFF37B24D)],
                ),
              ),
            ),
          ),
        ),

        // PNG image overlay
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),

        // Milestone indicators
        ..._buildMilestones(),
      ],
    );
  }

  List<Widget> _buildMilestones() {
    final widgets = <Widget>[];

    for (int i = 0; i < milestones.length; i++) {
      final milestone = milestones[i];
      final x = milestone * 300; // Use fixed width or pass context

      widgets.add(
        Positioned(
          left: x - 12, // Center the milestone
          top: milestoneYOffset,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: progress >= milestone ? Colors.yellow : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: progress >= milestone
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: progress >= milestone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      );
    }

    return widgets;
  }
}
