import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageValidationResult {
  final bool isValid;
  final String reason;
  final double confidence;

  ImageValidationResult({
    required this.isValid,
    required this.reason,
    required this.confidence,
  });

  factory ImageValidationResult.fromJson(Map<String, dynamic> json) {
    return ImageValidationResult(
      isValid: json['isValid'] ?? false,
      reason: json['reason'] ?? 'No reason provided',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

class ImageValidator {
  static const String _basePrompt =
      '''You are a strict but fair task completion validator. Your job is to carefully examine an image and determine if it provides REASONABLE evidence that a specific task has been completed.

## VALIDATION CRITERIA (STRICT BUT FAIR):
- The image MUST show visual evidence that reasonably supports task completion
- Vague, unclear, or ambiguous images should be REJECTED
- Images that could be interpreted in multiple ways should be REJECTED
- Images that don't directly relate to the task objective should be REJECTED
- Poor quality images (blurry, dark, unclear) should be REJECTED
- Images showing only partial completion should be REJECTED
- However, consider that some tasks are inherently difficult to prove with a single image
- For transportation tasks (walking, cycling, public transport), look for evidence like:
  * Person walking/cycling in appropriate clothing/gear
  * Bicycle or walking shoes visible
  * Location context that suggests active transportation
  * Time/weather conditions that support the activity
  * Note: A single image can't prove frequency (e.g., "per week"), but it can show the activity
- For other tasks, require more concrete evidence

## EVALUATION PROCESS:
1. First, clearly identify what the task objective is
2. Consider the nature of the task and what would constitute reasonable proof
3. Examine the image carefully for visual evidence
4. Ask: "Does this image provide reasonable evidence that the task was completed?"
5. If there's significant uncertainty or the image is unclear, REJECT
6. APPROVE if the evidence reasonably supports task completion
7. Remember: Be strict but fair - don't require impossible levels of proof

## RESPONSE FORMAT:
Respond with either:
- "APPROVED: [specific reason why this image provides reasonable evidence]"
- "REJECTED: [specific reason why this image fails to provide reasonable evidence]"

## FINAL GUIDANCE:
Be strict but reasonable. Some tasks are harder to prove than others. Focus on whether the image provides reasonable evidence, not irrefutable proof. When in doubt about clarity or relevance, reject. When the evidence is reasonable for the task type, approve.

## EXAMPLE FOR TRANSPORTATION TASKS:
For "Replace one short car trip per week with walking or cycling":
- APPROVE if: Image shows person walking/cycling in appropriate context (park, street, trail)
- REJECT if: Image is unclear, shows unrelated activity, or poor quality
- Note: The image can't prove "per week" frequency, but it can show the walking/cycling activity

## TASK OBJECTIVE TO VALIDATE:
''';

  /// Validates an image against a task objective using LLM API
  static Future<ImageValidationResult> validateImage({
    required String imagePath,
    required String taskObjective,
    String? apiEndpoint,
  }) async {
    try {
      // Load environment variables
      await dotenv.load();

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      final model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY not found in environment variables');
      }

      // Build the validation prompt
      final String fullPrompt = _basePrompt + taskObjective;

      // Convert image to base64
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Determine image MIME type
      final String mimeType = _getMimeType(imagePath);

      // Prepare the API request
      final Map<String, dynamic> requestBody = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a strict but fair task completion validator. You must be rigorous but reasonable. Consider the nature of each task and what would constitute reasonable proof. When in doubt about clarity or relevance, reject. When the evidence reasonably supports the task, approve.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': fullPrompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 200,
        'temperature':
            0.0, // Zero temperature for strict, deterministic validation
      };

      // Make the API call
      final response = await http.post(
        Uri.parse(apiEndpoint ?? 'https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String content = data['choices'][0]['message']['content'];

        // Parse the LLM response to determine validation result
        return _parseValidationResponse(content, taskObjective);
      } else {
        throw Exception(
            'API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error validating image: $e');
      // Return a default result that rejects the image (conservative approach)
      return ImageValidationResult(
        isValid: false,
        reason:
            'Image validation failed - insufficient evidence to approve (conservative approach)',
        confidence: 0.3,
      );
    }
  }

  /// Parse the LLM response to determine if the image is valid
  static ImageValidationResult _parseValidationResponse(
      String response, String taskObjective) {
    final String lowerResponse = response.toLowerCase();

    // Look for clear indicators of approval (must be explicit)
    if (lowerResponse.contains('approved:') ||
        lowerResponse.contains('approved') ||
        lowerResponse.contains('pass') ||
        lowerResponse.contains('valid') ||
        lowerResponse.contains('good') ||
        lowerResponse.contains('acceptable') ||
        lowerResponse.contains('sufficient') ||
        lowerResponse.contains('yes') ||
        lowerResponse.contains('affirmative')) {
      return ImageValidationResult(
        isValid: true,
        reason: 'Image shows clear and conclusive evidence of task completion',
        confidence: 0.97,
      );
    }

    // Look for clear indicators of rejection
    if (lowerResponse.contains('rejected:') ||
        lowerResponse.contains('rejected') ||
        lowerResponse.contains('fail') ||
        lowerResponse.contains('invalid') ||
        lowerResponse.contains('poor') ||
        lowerResponse.contains('unclear') ||
        lowerResponse.contains('insufficient') ||
        lowerResponse.contains('no') ||
        lowerResponse.contains('negative') ||
        lowerResponse.contains('ambiguous') ||
        lowerResponse.contains('uncertain')) {
      return ImageValidationResult(
        isValid: false,
        reason: _extractReason(response),
        confidence: 0.97,
      );
    }

    // If unclear, be conservative and reject
    return ImageValidationResult(
      isValid: false,
      reason:
          'Image validation unclear - insufficient evidence to approve (conservative validation)',
      confidence: 0.6,
    );
  }

  /// Extract the reason for rejection from the LLM response
  static String _extractReason(String response) {
    // Try to find a clear reason in the response
    final List<String> lines = response.split('\n');
    for (String line in lines) {
      if (line.toLowerCase().contains('because') ||
          line.toLowerCase().contains('reason') ||
          line.toLowerCase().contains('issue') ||
          line.toLowerCase().contains('problem')) {
        return line.trim();
      }
    }

    // If no clear reason found, return a generic message
    return 'Image does not clearly show task completion';
  }

  /// Get MIME type based on file extension
  static String _getMimeType(String filePath) {
    final String extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to JPEG
    }
  }

  /// Save validation result to a file for debugging
  static Future<void> saveValidationResult({
    required String imagePath,
    required String taskObjective,
    required ImageValidationResult result,
  }) async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String filePath = '${documentsDir.path}/image_validation_log.json';

      final Map<String, dynamic> logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'image_path': imagePath,
        'task_objective': taskObjective,
        'validation_result': {
          'isValid': result.isValid,
          'reason': result.reason,
          'confidence': result.confidence,
        },
      };

      // Read existing log or create new one
      final File file = File(filePath);
      List<Map<String, dynamic>> log = [];

      if (await file.exists()) {
        final String contents = await file.readAsString();
        log = List<Map<String, dynamic>>.from(jsonDecode(contents));
      }

      log.add(logEntry);

      // Save updated log
      await file.writeAsString(jsonEncode(log));

      print('✅ Validation result logged to: $filePath');
    } catch (e) {
      print('❌ Error saving validation log: $e');
    }
  }
}
