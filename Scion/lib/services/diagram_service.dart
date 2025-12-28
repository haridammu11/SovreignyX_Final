import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'groq_service.dart';
import '../utils/constants.dart' as constants;

class DiagramService {
  final GroqService _aiService;

  DiagramService({required GroqService aiService}) : _aiService = aiService;

  /// Generate a diagram description that can be rendered as an image
  Future<String> generateDiagramDescription({
    required String code,
    required String language,
    String? executionOutput,
    String? errorOutput,
    required DiagramType type,
  }) async {
    String prompt = '';

    switch (type) {
      case DiagramType.flowchart:
        prompt = '''
Create a detailed flowchart description for this $language code execution. 
Return ONLY a Mermaid.js flowchart syntax that visually represents the code flow.

Code:
```
$code
```

${executionOutput != null ? 'Execution Output:\n$executionOutput\n\n' : ''}
${errorOutput != null ? 'Error Output:\n$errorOutput\n\n' : ''}

Requirements:
1. Use mermaid flowchart LR syntax
2. Include all major execution paths
3. Show decision points with Yes/No branches
4. Represent loops with proper looping arrows
5. Show function calls as subgraphs
6. Label all nodes clearly
7. Use appropriate shapes (round for start/end, diamond for decisions, rectangle for processes)

Example format:
flowchart LR
    A[Start] --> B[Initialize Variables]
    B --> C{Condition?}
    C -->|Yes| D[Process Block]
    C -->|No| E[Alternative Block]
    D --> F[End]
    E --> F
    
Return ONLY the mermaid syntax, nothing else.
''';
        break;

      case DiagramType.sequence:
        prompt = '''
Create a detailed sequence diagram description for this $language code execution.
Return ONLY a Mermaid.js sequence diagram syntax that shows the interaction between components.

Code:
```
$code
```

Requirements:
1. Use mermaid sequenceDiagram syntax
2. Show the flow of execution between different components/parts
3. Include activation boxes for active periods
4. Show return messages where appropriate
5. Label participants clearly

Return ONLY the mermaid syntax, nothing else.
''';
        break;

      case DiagramType.state:
        prompt = '''
Create a detailed state diagram description for this $language code execution.
Return ONLY a Mermaid.js stateDiagram syntax that shows the different states and transitions.

Code:
```
$code
```

${executionOutput != null ? 'Execution Output:\n$executionOutput\n\n' : ''}
${errorOutput != null ? 'Error Output:\n$errorOutput\n\n' : ''}

Requirements:
1. Use mermaid stateDiagram-v2 syntax
2. Show all possible states during execution
3. Show transitions between states with labels
4. Include start and end states
5. Show error states if applicable

Return ONLY the mermaid syntax, nothing else.
''';
        break;
    }

    return await _aiService.sendMessage(prompt);
  }

  /// Generate a styled explanation with diagrammatic elements
  Future<String> generateStyledExplanation({
    required String code,
    required String language,
    String? executionOutput,
    String? errorOutput,
    required String diagramDescription,
    required DiagramType diagramType,
  }) async {
    final prompt = '''
${constants.AppConstants.codeAssistantPrompt}

Create a beautifully styled and well-organized explanation of the $language code execution with embedded diagrammatic elements. Present the information in a clear, structured format that separates code from explanations.

Code:
```
$code
```

${executionOutput != null ? 'Execution Output:\n$executionOutput\n\n' : ''}
${errorOutput != null ? 'Error Output:\n$errorOutput\n\n' : ''}

Diagram (Mermaid syntax):
```
$diagramDescription
```

STRUCTURE YOUR RESPONSE AS FOLLOWS WITH STRICT SEPARATION OF CODE AND EXPLANATIONS:

## 🎨 VISUAL EXECUTION MAP
\`\`\`mermaid
[THE MERMAID DIAGRAM WILL BE INSERTED HERE]
\`\`\`

## 📋 OVERVIEW
Provide a brief summary of what this code does in 2-3 sentences.

## 🔍 DETAILED EXECUTION FLOW

### Phase 1: Initialization
**Code Section:**
```$language
[Relevant code lines for this phase]
```
**Explanation:**
- What happens in this phase
- Variables initialized
- Initial state

### Phase 2: Processing
**Code Section:**
```$language
[Relevant code lines for this phase]
```
**Explanation:**
- Step-by-step execution
- Condition evaluations
- Loop iterations
- Function calls

### Phase 3: Output/Result
**Code Section:**
```$language
[Relevant code lines for this phase]
```
**Explanation:**
- Final processing
- Output generation
- Return values

## 🔄 STATE TRANSITIONS
Show how program state changes over time:

| Step | Code Line | Variables | Memory State | Next Action |
|------|-----------|-----------|--------------|-------------|
| 1    | Line 1    | x=0       | Stack: []    | Initialize  |
| 2    | Line 2    | x=5       | Stack: [x=5] | Process     |

## 💡 KEY INSIGHTS
- **Performance**: Time/space complexity notes
- **Best Practices**: What this demonstrates well
- **Common Pitfalls**: What to watch out for
- **Learning Points**: Takeaways for the student

Ensure clear separation between code blocks and explanations. Place all code in properly formatted code blocks and all explanations in plain text paragraphs. Do not mix inline code with explanations.
''';

    return await _aiService.sendMessage(prompt);
  }
}

enum DiagramType { flowchart, sequence, state }
