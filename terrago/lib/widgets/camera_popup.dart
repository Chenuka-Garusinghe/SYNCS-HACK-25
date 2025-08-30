import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'dart:convert';
import '../utils/image_validator.dart';

class CameraPopup extends StatefulWidget {
  final String taskText;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const CameraPopup({
    super.key,
    required this.taskText,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<CameraPopup> createState() => _CameraPopupState();
}

class _CameraPopupState extends State<CameraPopup> {
  bool _isProcessing = false;
  bool? _processingResult;
  String _resultMessage = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Complete Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                widget.taskText,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Show result if processing is complete
            if (_processingResult != null) ...[
              _buildResultWidget(),
            ] else if (_isProcessing) ...[
              _buildProcessingWidget(),
            ] else ...[
              _buildCameraOptions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOptions() {
    return Column(
      children: [
        Text(
          'Take a photo or upload an image to show your progress!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingWidget() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.2),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100],
                  border: Border.all(
                    color: Colors.blue[300]!
                        .withOpacity(0.8 + (value - 0.8) * 0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, -1),
                          child: const Text(
                            '🧠', // Brain emoji
                            style: TextStyle(fontSize: 50),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Thinking',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const _AnimatedDots(),
          ],
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          'Analyzing your image...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultWidget() {
    final isSuccess = _processingResult == true;
    return Column(
      children: [
        // Success or failure icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Result message
        Text(
          isSuccess ? 'Great job!' : 'Try again',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          _resultMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSuccess ? _handleSuccess : _handleRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isSuccess ? 'Continue' : 'Try Again'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final ImagePicker picker = ImagePicker();

      // Add timeout and better error handling
      final XFile? image = await picker
          .pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Camera operation timed out');
        },
      );

      if (image != null) {
        // Save and process the image
        await _saveImage(image);
      } else {
        // User cancelled
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      String errorMessage = 'Error accessing camera/gallery. ';

      if (e.toString().contains('permission')) {
        errorMessage +=
            'Please check camera and storage permissions in your device settings.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Operation timed out. Please try again.';
      } else {
        errorMessage += 'Please try again.';
      }

      setState(() {
        _isProcessing = false;
        _processingResult = false;
        _resultMessage = errorMessage;
      });
    }
  }

  Future<void> _saveImage(XFile image) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${tempDir.path}/$fileName';

      final File imageFile = File(image.path);
      await imageFile.copy(filePath);

      _processImage(filePath);
    } catch (e) {
      print('❌ Error saving image: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final ImageValidationResult result = await ImageValidator.validateImage(
        imagePath: imagePath,
        taskObjective: widget.taskText,
      );

      await ImageValidator.saveValidationResult(
        imagePath: imagePath,
        taskObjective: widget.taskText,
        result: result,
      );

      setState(() {
        _isProcessing = false;
        _processingResult = result.isValid;
        _resultMessage = result.isValid
            ? 'Great! Your task has been completed successfully!'
            : result.reason;
      });
    } catch (e) {
      print('❌ Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _processingResult = false;
        _resultMessage = 'Error processing image. Please try again.';
      });
    }
  }

  void _handleSuccess() {
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pop();
      widget.onSuccess();
    });
  }

  void _handleRetry() {
    setState(() {
      _processingResult = null;
      _resultMessage = '';
    });
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _controller.addListener(() {
      final progress = _controller.value;
      if (progress < 0.33) {
        if (_dotCount != 1) {
          setState(() => _dotCount = 1);
        }
      } else if (progress < 0.66) {
        if (_dotCount != 2) {
          setState(() => _dotCount = 2);
        }
      } else {
        if (_dotCount != 3) {
          setState(() => _dotCount = 3);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        '.' * _dotCount,
        key: ValueKey(_dotCount),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue[600],
        ),
      ),
    );
  }
}
