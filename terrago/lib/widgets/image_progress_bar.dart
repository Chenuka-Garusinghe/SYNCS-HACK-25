import 'package:flutter/material.dart';

class ImageProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final String imagePath;
  final List<double> milestones;
  final List<double>
      milestoneYOffsets; // Array of Y positions for each milestone
  final VoidCallback? onMilestoneReached;
  final int activeMilestones; // Number of milestones to make yellow (1-4)

  const ImageProgressBar({
    super.key,
    required this.progress,
    required this.height,
    required this.imagePath,
    this.milestones = const [0.0, 0.25, 0.5, 0.75, 1.0],
    this.milestoneYOffsets = const [
      40.0,
      40.0,
      40.0,
      40.0,
      40.0
    ], // Default Y positions
    this.onMilestoneReached,
    this.activeMilestones = 1, // Default: first milestone is yellow
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base container (just for sizing, no green progress)
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
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

      // Get the Y offset for this specific milestone
      final yOffset =
          i < milestoneYOffsets.length ? milestoneYOffsets[i] : 40.0;

      // Milestone is yellow if it's within the activeMilestones count
      final isActive = i < activeMilestones;

      widgets.add(
        Positioned(
          left: x - 12, // Center the milestone
          top: yOffset, // Use individual Y offset for each milestone
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.yellow : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      );
    }

    return widgets;
  }
}
