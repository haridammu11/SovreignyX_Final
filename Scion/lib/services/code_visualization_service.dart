import 'groq_service.dart';
import 'diagram_service.dart';
import '../utils/constants.dart' as constants;

class CodeVisualizationService {
  final GroqService _aiService;
  late final DiagramService _diagramService;

  CodeVisualizationService({required GroqService aiService})
    : _aiService = aiService {
    _diagramService = DiagramService(aiService: aiService);
  }

  /// Generate a dramatic visualization of code execution flow with visual elements
  Future<String> generateExecutionVisualization({
    required String code,
    required String language,
    String? executionOutput,
    String? errorOutput,
  }) async {
    // Check if service is properly initialized
    if (_aiService == null) {
      throw Exception(
        'AI service not initialized. Please check your API key configuration.',
      );
    }

    try {
      // Generate a flowchart diagram description
      final diagramDescription = await _diagramService
          .generateDiagramDescription(
            code: code,
            language: language,
            executionOutput: executionOutput,
            errorOutput: errorOutput,
            type: DiagramType.flowchart,
          );

      // Generate a styled explanation with the diagram
      final styledExplanation = await _diagramService.generateStyledExplanation(
        code: code,
        language: language,
        executionOutput: executionOutput,
        errorOutput: errorOutput,
        diagramDescription: diagramDescription,
        diagramType: DiagramType.flowchart,
      );

      return styledExplanation;
    } catch (e) {
      // Fallback to text-based visualization if diagram generation fails
      return await _generateTextBasedVisualization(
        code: code,
        language: language,
        executionOutput: executionOutput,
        errorOutput: errorOutput,
      );
    }
  }

  /// Generate debugging assistance with visual debugging aids
  Future<String> generateDebuggingGuide({
    required String code,
    required String language,
    required String errorOutput,
  }) async {
    // Check if service is properly initialized
    if (_aiService == null) {
      throw Exception(
        'AI service not initialized. Please check your API key configuration.',
      );
    }

    final prompt = '''
${constants.AppConstants.codeAssistantPrompt}

Act as an expert debugger helping a student understand and fix their $language code. Create a well-structured debugging guide with clear separation between code and explanations.

Problematic Code:
```
$code
```

Error Message:
$errorOutput

STRUCTURE YOUR RESPONSE AS FOLLOWS WITH STRICT SEPARATION OF CODE AND EXPLANATIONS:

## 🎯 ERROR ANALYSIS
**Error Location:** Line X
**Error Type:** [Syntax/Runtime/Logic] Error
**Brief Description:** One sentence explaining the error

## 🔍 DETAILED EXPLANATION
**What Went Wrong:**
Clear explanation of the root cause without mixing code inline

**Why It Happened:**
Educational explanation of the underlying concept

## 🛠️ STEP-BY-STEP SOLUTION

### Step 1: Identify the Problem
**Problematic Code:**
```$language
[Exact problematic code section]
```
**Issue:** Explanation of what's wrong with this code

### Step 2: Apply the Fix
**Corrected Code:**
```$language
[Fixed code section]
```
**Fix Explanation:** What was changed and why

### Step 3: Verify the Solution
**Verification Approach:** How to confirm the fix works

## 📈 DEBUGGING FLOWCHART
Visual representation of the debugging process:
┌─────────────┐
│  START      │
└──────┬──────┘
       ▼
┌─────────────┐    YES
│  ERROR?     │ ──────► ┌─────────────┐
└──────┬──────┘         │  FIX ERROR  │
       │ NO             └─────────────┘
       ▼
┌─────────────┐
│  CONTINUE   │
└─────────────┘

## 📚 PREVENTION STRATEGIES
- **Best Practice 1:** Description with example
- **Best Practice 2:** Description with example
- **Common Pitfall:** What to avoid with example

Ensure clear separation between code blocks and explanations. Place all code in properly formatted code blocks and all explanations in plain text paragraphs. Do not mix inline code with explanations.
''';

    return await _aiService.sendMessage(prompt);
  }

  /// Generate interactive learning with visual learning paths
  Future<String> generateInteractiveLearning({
    required String code,
    required String language,
    String? executionOutput,
  }) async {
    // Check if service is properly initialized
    if (_aiService == null) {
      throw Exception(
        'AI service not initialized. Please check your API key configuration.',
      );
    }

    final prompt = '''
${constants.AppConstants.codeAssistantPrompt}

Transform the following $language code into a well-structured interactive learning experience with clear separation between code examples and explanations.

Code:
```
$code
```

${executionOutput != null ? 'Output:\n$executionOutput\n\n' : ''}

STRUCTURE YOUR RESPONSE AS FOLLOWS WITH STRICT SEPARATION OF CODE AND EXPLANATIONS:

## 📋 CONCEPT OVERVIEW
**Topic:** [Programming concept demonstrated]
**Difficulty Level:** [Beginner/Intermediate/Advanced]
**Estimated Time:** [Time to complete]

## 🎯 LEARNING OBJECTIVES
List 3-5 specific learning goals for this lesson

## 🧠 THEORY EXPLAINED

### Core Concept
Clear explanation of the main programming concept without mixing code inline

### Why It Matters
Real-world applications and importance of this concept

## 💻 HANDS-ON EXAMPLE

### Example 1: Basic Usage
**Code Sample:**
```$language
[Simple code demonstrating the concept]
```
**Explanation:**
Step-by-step breakdown of what this code does

### Example 2: Intermediate Usage
**Code Sample:**
```$language
[More complex code building on the concept]
```
**Explanation:**
Detailed walkthrough of the implementation

## 🔄 VARIATIONS AND EXTENSIONS

### Variation 1: [Description]
**Modified Code:**
```$language
[Code showing a variation of the concept]
```
**Difference Explained:**
What changed and why it matters

### Variation 2: [Description]
**Modified Code:**
```$language
[Code showing another variation]
```
**Difference Explained:**
What changed and why it matters

## ⚡ CHALLENGE LAB

### Beginner Challenge
**Task:** [Simple modification task]
**Starting Code:**
```$language
[Code to modify]
```
**Goal:** What the student should accomplish

### Intermediate Challenge
**Task:** [Moderate complexity task]
**Starting Code:**
```$language
[Code to modify]
```
**Goal:** What the student should accomplish

### Advanced Challenge
**Task:** [Complex task]
**Starting Code:**
```$language
[Code to modify]
```
**Goal:** What the student should accomplish

## 📊 KNOWLEDGE CHECK
- **Question 1:** [Conceptual question]
- **Question 2:** [Practical application question]
- **Question 3:** [Critical thinking question]

## 🌟 REAL-WORLD APPLICATIONS
- **Industry Use Case 1:** Description with example
- **Industry Use Case 2:** Description with example
- **Career Relevance:** How this skill applies professionally

Ensure clear separation between code blocks and explanations. Place all code in properly formatted code blocks and all explanations in plain text paragraphs. Do not mix inline code with explanations.
''';

    return await _aiService.sendMessage(prompt);
  }

  /// Fallback text-based visualization
  Future<String> _generateTextBasedVisualization({
    required String code,
    required String language,
    String? executionOutput,
    String? errorOutput,
  }) async {
    final prompt = '''
${constants.AppConstants.codeAssistantPrompt}

Create a well-organized and cleanly structured visualization of the execution flow for the following $language code. Present the information in a clear format that separates code from explanations.

Code to visualize:
```
$code
```

${executionOutput != null ? 'Execution Output:\n$executionOutput\n\n' : ''}
${errorOutput != null ? 'Error Output:\n$errorOutput\n\n' : ''}

STRUCTURE YOUR RESPONSE AS FOLLOWS WITH STRICT SEPARATION OF CODE AND EXPLANATIONS:

## 🎬 EXECUTION OVERVIEW
Provide a brief narrative summary of the code execution in 2-3 sentences.

## 🔍 STEP-BY-STEP EXECUTION

### Step 1: [Description of Phase]
**Code Section:**
```$language
[Relevant code lines for this step]
```
**Execution Details:**
- What happens in this step
- Variables affected: [var1=value1, var2=value2]
- Memory changes: [heap/stack updates]
- Control flow: [next step or jump]

### Step 2: [Description of Phase]
**Code Section:**
```$language
[Relevant code lines for this step]
```
**Execution Details:**
- What happens in this step
- Variables affected: [var1=value1, var2=value2]
- Memory changes: [heap/stack updates]
- Control flow: [next step or jump]

(Continue with additional steps as needed)

## 📊 VISUAL FLOW REPRESENTATION
Represent the execution flow using a clear ASCII flowchart:
┌─────────────┐
│   START     │
└──────┬──────┘
       ▼
┌─────────────┐
│Initialize   │
│Variables    │
└──────┬──────┘
       ▼
┌─────────────┐    YES
│Condition?   │─────▶ [Action if true]
└──────┬──────┘
       │ NO
       ▼
[Action if false]

## 🎨 STATE TRANSITION TABLE
Show how variables and program state change over time:

| Step | Line | Variables     | Memory State    | Next Step |
|------|------|---------------|-----------------|-----------|
| 1    | 1    | x=undefined   | Stack: []       | → Step 2  |
| 2    | 2    | x=5           | Stack: [x=5]    | → Step 3  |
| 3    | 3    | x=5, y=10     | Stack: [x=5,y=10]| → Step 4 |

## 💡 EDUCATIONAL INSIGHTS
- **Key Concept**: What important programming concept is demonstrated
- **Best Practice**: What this code does well
- **Common Mistake**: What errors users might make with similar code
- **Performance Note**: Time/space complexity considerations

Ensure clear separation between code blocks and explanations. Place all code in properly formatted code blocks and all explanations in plain text paragraphs. Do not mix inline code with explanations.
''';

    return await _aiService.sendMessage(prompt);
  }
}
