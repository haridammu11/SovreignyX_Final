import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import 'groq_service.dart';

class ProjectGeneratorService {
  final GroqService _groqService;

  ProjectGeneratorService(this._groqService);

  Future<List<Project>> generateProjectOptions(String courseTopic) async {
    final prompt = '''
    Generate 3 software project ideas relevant to the course topic: "$courseTopic".
    
    1. One "Moderate" level project.
    2. Two "Production-Level" projects.
    
    For each project, provide:
    - Title
    - Brief Description (1-2 sentences)
    - Key Learning Objectives (3-4 bullet points)
    - Primary Language (e.g., Python, Javascript, Dart)

    Format the output strictly as a JSON list of objects:
    [
      {
        "title": "...",
        "description": "...",
        "difficulty": "Moderate" | "Production",
        "language": "...",
        "objectives": ["...", "..."]
      }
    ]
    Do not include markdown formatting (like ```json), just the raw JSON.
    ''';

    try {
      final response = await _groqService.sendMessage(prompt);
      final cleanResponse = _extractJson(response);
      
      final List<dynamic> data = jsonDecode(cleanResponse);
      
      return data.map((item) => Project(
        id: const Uuid().v4(),
        title: item['title'],
        description: item['description'],
        difficulty: item['difficulty'],
        language: item['language'],
        objectives: List<String>.from(item['objectives']),
      )).toList();
    } catch (e) {
      print('Error generating project options: $e');
      // Fallback
      return [
        Project(
          id: const Uuid().v4(),
          title: '$courseTopic Starter Project',
          description: 'A simple project to practice $courseTopic concepts.',
          difficulty: 'Moderate',
          language: 'Python',
          objectives: ['Learn basics', 'Implement simple logic'],
        )
      ];
    }
  }

  Future<Project> populateProjectFiles(Project project) async {
    final prompt = '''
    Create a complete multi-file project structure for: "${project.title}" (${project.description}).
    Language: ${project.language}.
    Difficulty: ${project.difficulty}.

    You must generate the complete source code for all necessary files.
    
    Format the output strictly as a JSON object where keys are filenames and values are the file content strings.
    Example:
    {
      "main.py": "print('Hello')",
      "utils.py": "def helper(): pass",
      "README.md": "# Project Title..."
    }
    
    Ensure the code is functional and production-quality if requested.
    Do not include markdown formatting, just the raw JSON.
    ''';

    try {
      final response = await _groqService.sendMessage(prompt);
      final cleanResponse = _extractJson(response);
      
      final Map<String, dynamic> filesData = jsonDecode(cleanResponse);
      final Map<String, String> files = filesData.map((key, value) => MapEntry(key, value.toString()));
      
      project.files = files;
      return project;
    } catch (e) {
      print('Error generating project files: $e');
      print('Raw Response was possibly invalid JSON.');
      
      // Fallback: Create a basic structure if AI fails
      project.files = {
        'README.md': '# ${project.title}\n\n${project.description}\n\nGenerated fallback due to AI error.',
        'main.${project.language == 'Python' ? 'py' : 'js'}': '// Start coding here\nprint("Hello World")',
      };
      return project;
    }
  }

  /// Helper to extract JSON from potentially Markdown-wrapped text
  String _extractJson(String text) {
     text = text.trim();
     // Remove markdown code blocks
     text = text.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
     text = text.replaceAll(RegExp(r'^```\s*', multiLine: true), '');
     text = text.replaceAll(RegExp(r'```$', multiLine: true), '');
     
     // Find first '{' or '['
     int firstBrace = text.indexOf('{');
     int firstBracket = text.indexOf('[');
     
     int start = -1;
     int end = -1;
     
     if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
        start = firstBrace;
        end = text.lastIndexOf('}');
     } else if (firstBracket != -1) {
        start = firstBracket;
        end = text.lastIndexOf(']');
     }
     
     if (start != -1 && end != -1 && end > start) {
        return text.substring(start, end + 1);
     }
     
     return text; // Return original if no structure found, hoping for the best
  }
  
  Future<String> getAgentAssistance(Project project, String currentFile, String code, String userQuery) async {
    final prompt = '''
    You are an AI Coding Agent assisting a user with the project: "${project.title}".
    Current File: $currentFile
    
    Current File Content:
    $code
    
    User Query: "$userQuery"
    
    Provide a helpful response. If you suggest code, provide it in a code block. 
    Explain your reasoning like a senior engineer.
    ''';
    
    return await _groqService.sendMessage(prompt);
  }
}
