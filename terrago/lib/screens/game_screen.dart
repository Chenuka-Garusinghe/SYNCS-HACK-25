import 'package:flutter/material.dart';
import 'package:terrago/widgets/image_progress_bar.dart';
import 'package:terrago/widgets/task_item_holder.dart';
import 'package:terrago/widgets/camera_popup.dart';
import 'dart:convert';
import 'dart:io';

class GameScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  double progress = 0.0;
  List<String> allTasks = [];
  List<String> currentTasks = [];
  int currentTaskIndex = 0;
  int currentBatchIndex = 0;
  int tasksPerBatch = 4;

  final List<AnimationController> _bounceControllers = [];
  final List<Animation<double>> _bounceAnimations = [];
  final milestones = <double>[0.15, 0.4, 0.65, 0.90, 1.15];
  // final milestoneYOffsets = <double>[40.0, 44.0, 40.0, 36.0, 46.0];
  final milestoneYOffsets = <double>[60.0, 64.0, 60.0, 56.0, 66.0];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeAnimations();
  }

  @override
  void dispose() {
    for (var controller in _bounceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    for (int i = 0; i < tasksPerBatch; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );

      _bounceControllers.add(controller);
      _bounceAnimations.add(animation);
    }
  }

  Future<void> _loadTasks() async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String actionsJsonPath = '${documentsDir.path}/actions.json';

      final File actionsFile = File(actionsJsonPath);
      if (await actionsFile.exists()) {
        final String actionsContent = await actionsFile.readAsString();
        final Map<String, dynamic> actionsData = jsonDecode(actionsContent);

        setState(() {
          allTasks = List<String>.from(actionsData['actions'] ?? []);
          _loadCurrentBatch();
        });
      } else {
        // Fallback tasks if actions.json doesn't exist
        setState(() {
          allTasks = [
            'Replace one short car trip per week with walking or cycling',
            'Combine errands to reduce the number of car trips',
            'Practice fuel-efficient driving habits like gentle acceleration',
            'Have one meat-free meal per week',
            'Wash clothes in cold water to save energy',
            'Turn off lights when leaving rooms',
            'Use reusable shopping bags and water bottles',
            'Reduce shower time by one minute to save water and energy',
          ];
          _loadCurrentBatch();
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
      // Fallback tasks
      setState(() {
        allTasks = [
          'Replace one short car trip per week with walking or cycling',
          'Combine errands to reduce the number of car trips',
          'Practice fuel-efficient driving habits like gentle acceleration',
          'Have one meat-free meal per week',
          'Wash clothes in cold water to save energy',
          'Turn off lights when leaving rooms',
          'Use reusable shopping bags and water bottles',
          'Reduce shower time by one minute to save water and energy',
        ];
        _loadCurrentBatch();
      });
    }
  }

  void _loadCurrentBatch() {
    final startIndex = currentBatchIndex * tasksPerBatch;
    final endIndex = (startIndex + tasksPerBatch).clamp(0, allTasks.length);

    setState(() {
      currentTasks = allTasks.sublist(startIndex, endIndex);
      currentTaskIndex = 0;
    });
  }

  void _loadNextBatch() {
    if ((currentBatchIndex + 1) * tasksPerBatch < allTasks.length) {
      setState(() {
        currentBatchIndex++;
        _loadCurrentBatch();
      });
    } else {
      // All tasks completed, reset to beginning
      setState(() {
        currentBatchIndex = 0;
        _loadCurrentBatch();
      });
    }
  }

  void updateProgress(double newProgress) {
    setState(() {
      progress = newProgress.clamp(0.0, 1.0);
    });
  }

  void _onCameraTap(int taskIndex) {
    if (taskIndex == currentTaskIndex) {
      // Correct task - show camera popup
      _showCameraPopup(taskIndex);
    } else {
      // Wrong task - bounce animation
      _bounceControllers[taskIndex].forward().then((_) {
        _bounceControllers[taskIndex].reverse();
      });
    }
  }

  void _showCameraPopup(int taskIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CameraPopup(
          taskText: currentTasks[taskIndex],
          onSuccess: () => _completeTask(),
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _completeTask() {
    setState(() {
      currentTaskIndex++;

      // Update progress based on completed tasks in current batch
      final batchProgress = currentTaskIndex / currentTasks.length;
      final totalProgress = (currentBatchIndex + batchProgress) /
          ((allTasks.length / tasksPerBatch).ceil());
      progress = totalProgress.clamp(0.0, 1.0);
    });

    // Check if current batch is complete
    if (currentTaskIndex >= currentTasks.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadNextBatch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
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
                    height: 220.0,
                    imagePath: 'assets/ui/branch.png',
                    milestones: milestones,
                    milestoneYOffsets:
                        milestoneYOffsets, // Individual Y positions for each milestone
                    activeMilestones: currentTaskIndex +
                        1, // 1 for first task, 2 for second, etc.
                  ),
                ],
              ),
            ),
            // child 3: Task List
            Expanded(
              child: CustomScrollView(
                // iOS 18 notification center style physics
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Tasks (${currentBatchIndex + 1}/${(allTasks.length / tasksPerBatch).ceil()})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${currentTaskIndex}/${currentTasks.length} completed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Task items with iOS-style stacking
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = currentTasks[index];
                        final isCompleted = index < currentTaskIndex;
                        final isCurrentTask = index == currentTaskIndex;

                        return AnimatedBuilder(
                          animation: _bounceAnimations[index],
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                  0, _bounceAnimations[index].value * 10),
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: index == currentTasks.length - 1
                                      ? 16.0
                                      : 8.0,
                                ),
                                child: TaskItemHolder(
                                  taskText: task,
                                  isCompleted: isCompleted,
                                  onCameraTap: () => _onCameraTap(index),
                                  dotColor: isCurrentTask ? Colors.green : null,
                                  textColor:
                                      isCurrentTask ? Colors.green[700] : null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: currentTasks.length,
                    ),
                  ),
                  // Bottom padding for better scroll experience
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
