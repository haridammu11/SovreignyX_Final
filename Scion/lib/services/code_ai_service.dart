import 'groq_service.dart';
import '../utils/constants.dart';

class CodeAIService {
  final GroqService _aiService;

  CodeAIService({required GroqService aiService}) : _aiService = aiService;

  /// Correct code errors and provide suggestions
  Future<String> correctCode({
    required String code,
    required String language,
    String? errorOutput,
  }) async {
    final prompt = '''
${AppConstants.codeAssistantPrompt}

Analyze the following $language code and provide corrections for any errors.

${errorOutput != null ? 'The code produced the following error output:\n$errorOutput\n\n' : ''}

Code to fix:
```
$code
```

Please provide:
1. A brief explanation of what was wrong with the code
2. The corrected code
3. A short explanation of the fix

Format your response clearly with headings and code blocks.
''';

    return await _aiService.sendMessage(prompt);
  }

  /// Generate code based on a description
  Future<String> generateCode({
    required String description,
    required String language,
  }) async {
    final prompt = '''
${AppConstants.codeAssistantPrompt}

Generate a $language program that accomplishes the following task:

Task: $description

Please provide:
1. The complete code
2. A brief explanation of how the code works
3. Any important concepts demonstrated

Format your response clearly with headings and code blocks.
''';

    return await _aiService.sendMessage(prompt);
  }

  /// Explain code functionality
  Future<String> explainCode({
    required String code,
    required String language,
  }) async {
    final prompt = '''
${AppConstants.codeAssistantPrompt}

Explain the following $language code in simple terms:

Code to explain:
```
$code
```

Please provide:
1. What the code does overall
2. Explanation of key parts/functions
3. Any important programming concepts demonstrated
4. Suggestions for improvement (if applicable)

Format your response clearly with headings.
''';

    return await _aiService.sendMessage(prompt);
  }
}
