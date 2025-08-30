import 'package:flutter/material.dart';
import 'package:terrago/widgets/image_progress_bar.dart';
import 'package:terrago/widgets/task_item_holder.dart';
import 'package:terrago/widgets/camera_popup.dart';
import 'package:terrago/screens/explore_page.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class GameScreen extends StatefulWidget {
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
  final milestoneYOffsets = <double>[32.0, 36.0, 26.0, 34.0, 36.0];

  // GIF states for smooth transitions
  String _currentLoopingGif = 'assets/rivs/t_0.gif';
  String _transitionGif = '';
  bool _isTransitioning = false;

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
        // fallbacks
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

  Map<String, String> _getGifAssetsForMilestone() {
    if (currentTaskIndex == 0) {
      return {
        'looping': 'assets/rivs/t_0.gif',
        'transition': '',
      };
    } else if (currentTaskIndex == 1) {
      return {
        'looping': 'assets/rivs/t_1.gif',
        'transition': 'assets/rivs/t_0-t_1.gif',
      };
    } else if (currentTaskIndex == 2) {
      // No transition GIF exists for t_1 to t_2, so skip transition
      return {
        'looping':
            'assets/rivs/t_1.gif', // Keep using t_1 since t_2 doesn't exist
        'transition': '',
      };
    } else if (currentTaskIndex >= 3) {
      // No transition GIF exists for t_2 to t_3, so skip transition
      return {
        'looping':
            'assets/rivs/t_1.gif', // Keep using t_1 since t_3 doesn't exist
        'transition': '',
      };
    } else {
      return {
        'looping': 'assets/rivs/t_0.gif',
        'transition': '',
      };
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

      final batchProgress = currentTaskIndex / currentTasks.length;
      final totalProgress = (currentBatchIndex + batchProgress) /
          ((allTasks.length / tasksPerBatch).ceil());
      progress = totalProgress.clamp(0.0, 1.0);

      // Start transition to new milestone
      _startTransitionToNewMilestone();
    });
  }

  // Handle smooth transition between milestones
  void _startTransitionToNewMilestone() {
    final gifAssets = _getGifAssetsForMilestone();

    print('🎬 Starting transition: currentTaskIndex = $currentTaskIndex');
    print(' Transition GIF: ${gifAssets['transition']}');
    print(' Looping GIF: ${gifAssets['looping']}');

    if (gifAssets['transition']!.isNotEmpty) {
      print(' Playing transition GIF: ${gifAssets['transition']}');
      print(' Transition start time: ${DateTime.now()}');

      // Play transition GIF first
      setState(() {
        _isTransitioning = true;
        _transitionGif = gifAssets['transition']!;
        print(
            ' Transition state set: _isTransitioning = $_isTransitioning, _transitionGif = $_transitionGif');
      });

      // Calculate transition duration based on the specific GIF
      // Different transition GIFs may have different durations
      int transitionDuration = _getTransitionDuration(gifAssets['transition']!);

      print(' Transition duration: ${transitionDuration}ms');

      // After transition completes, switch to looping GIF
      Future.delayed(Duration(milliseconds: transitionDuration), () {
        print('🎬 Transition complete, switching to: ${gifAssets['looping']}');
        print(' Transition end time: ${DateTime.now()}');
        setState(() {
          _isTransitioning = false;
          _currentLoopingGif = gifAssets['looping']!;
          print(
              ' Transition state updated: _isTransitioning = $_isTransitioning, _currentLoopingGif = $_currentLoopingGif');
        });
      });
    } else {
      print(
          '🎬 No transition needed, directly updating to: ${gifAssets['looping']}');
      // No transition needed, directly update looping GIF
      setState(() {
        _currentLoopingGif = gifAssets['looping']!;
      });
    }
  }

  // Get the appropriate transition duration for each GIF
  int _getTransitionDuration(String transitionGif) {
    switch (transitionGif) {
      case 'assets/rivs/t_0-t_1.gif':
        return 5000; // 5 seconds for the large 13MB transition
      default:
        return 3000; // Default 3 seconds for unknown transitions
    }
  }

  void _loadCurrentBatch() {
    final startIndex = currentBatchIndex * tasksPerBatch;
    final endIndex = (startIndex + tasksPerBatch).clamp(0, allTasks.length);

    setState(() {
      currentTasks = allTasks.sublist(startIndex, endIndex);
      currentTaskIndex = 0;
      // Reset GIF to initial state for new batch
      _currentLoopingGif = 'assets/rivs/t_0.gif';
      _isTransitioning = false;
      _transitionGif = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.explore),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ExplorePage(),
              ),
            );
          },
        ),
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
        child: Stack(
          children: [
            // Background wallpaper with z-index -1
            Positioned.fill(
              child: Image.asset(
                'assets/ui/wallpaper.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Content overlay (everything else on top)
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                children: [
                  // child 1: avatar
                  // Large GIF Player
                  Container(
                    width: double.infinity,
                    height: 600.0,
                    color: Colors.transparent,
                    margin:
                        const EdgeInsets.only(top: 20.0), // Added top margin
                    child: Transform.translate(
                      offset: const Offset(-2, 0), // Move 100px to the left
                      child: SizedBox(
                        width: 1000.0,
                        height: 600.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              20.0), // Adjust this value for more/less rounded corners
                          child: Image.asset(
                            _isTransitioning
                                ? _transitionGif
                                : _currentLoopingGif,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // child 2: Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                    child: Column(
                      children: [
                        ImageProgressBar(
                          progress: progress,
                          height: 150.0,
                          imagePath: 'assets/ui/branch.png',
                          milestones: milestones,
                          milestoneYOffsets: milestoneYOffsets,
                          activeMilestones: currentTaskIndex + 1,
                        ),
                      ],
                    ),
                  ),
                  // child 3: Task List
                  Transform.translate(
                    offset: const Offset(0, -16.0),
                    child: Container(
                      child: Column(
                        children: [
                          // Header section
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                          // Task items with iOS-style stacking
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentTasks.length,
                            itemBuilder: (context, index) {
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
                                        dotColor:
                                            isCurrentTask ? Colors.green : null,
                                        textColor: isCurrentTask
                                            ? Colors.green[700]
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          // Bottom padding for better scroll experience
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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
