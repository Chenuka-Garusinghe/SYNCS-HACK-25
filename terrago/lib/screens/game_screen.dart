import 'package:flutter/material.dart';
import 'package:terrago/widgets/image_progress_bar.dart';
import 'package:terrago/widgets/task_item_holder.dart';

class GameScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double progress = 0.0;
  bool isTaskCompleted = false;

  // milestones positions
  final milestones = <double>[0.05, 0.28, 0.52, 0.77, 0.95];

  void updateProgress(double newProgress) {
    setState(() {
      progress = newProgress.clamp(0.0, 1.0);
    });
  }

  void _onCameraTap() {
    // TODO: Implement camera functionality
    setState(() {
      isTaskCompleted = !isTaskCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: Column(
        children: [
          // child 1: avatar
          const Column(
            children: [
              Text('Avatar'),
            ],
          ),
          // child 2: Progress bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar with PNG overlay
                ImageProgressBar(
                  progress: progress,
                  height: 120.0,
                  imagePath: 'assets/ui/image.png',
                  milestones: milestones,
                  milestoneYOffset:
                      40.0, // Adjust to position milestones over yellow circles
                ),
              ],
            ),
          ),
          // child 3: Task List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Current Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                TaskItemHolder(
                  taskText: "Capture evidence of your work",
                  isCompleted: isTaskCompleted,
                  onCameraTap: _onCameraTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
