import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

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

        // Camera and gallery buttons
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
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 16),
        Text(
          'Processing your image...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
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

        // Action button
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _isProcessing = true;
        });

        // Save the image
        await _saveImage(image);

        // Process the image (simulate processing)
        await _processImage(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isProcessing = false;
        _processingResult = false;
        _resultMessage = 'Error picking image. Please try again.';
      });
    }
  }

  Future<void> _saveImage(XFile image) async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'task_photo_$timestamp.jpg';
      final String filePath = '${documentsDir.path}/$fileName';

      // Copy the image to our temp directory
      await File(image.path).copy(filePath);

      print('✅ Photo saved to: $filePath');
    } catch (e) {
      print('❌ Error saving image: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));

      // Check the processing result from our hidden file
      final bool passesProcessing = await _checkProcessingResult();

      setState(() {
        _isProcessing = false;
        _processingResult = passesProcessing;
        _resultMessage = passesProcessing
            ? 'Your task has been completed successfully!'
            : 'The image doesn\'t meet the task requirements. Please try again.';
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

  Future<bool> _checkProcessingResult() async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String filePath = '${documentsDir.path}/processing_results.json';

      final File file = File(filePath);

      // Create the file if it doesn't exist with default settings
      if (!await file.exists()) {
        await _createDefaultProcessingFile(filePath);
      }

      // Read the processing rules
      final String contents = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(contents);

      // For now, return the default pass value (true)
      return data['default_pass'] ?? true;
    } catch (e) {
      print('❌ Error checking processing result: $e');
      // Default to true if there's an error
      return true;
    }
  }

  Future<void> _createDefaultProcessingFile(String filePath) async {
    try {
      final Map<String, dynamic> defaultData = {
        'default_pass': true,
        'created_at': DateTime.now().toIso8601String(),
        'note':
            'This file controls image processing results. Set default_pass to false to make images fail validation.',
        'rules': {
          'enable_ai_processing': false,
          'require_specific_objects': false,
          'minimum_quality_score': 0.0,
        }
      };

      final File file = File(filePath);
      await file.writeAsString(jsonEncode(defaultData));

      print('✅ Created processing results file: $filePath');
    } catch (e) {
      print('❌ Error creating processing file: $e');
    }
  }

  void _handleSuccess() {
    // Close the popup with a small delay and call success callback
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pop();
      widget.onSuccess();
    });
  }

  void _handleRetry() {
    // Reset the state to allow another attempt
    setState(() {
      _processingResult = null;
      _resultMessage = '';
    });
  }
}
