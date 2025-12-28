import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../services/code_execution_service.dart';
import '../services/project_generator_service.dart';

class IDEScreen extends StatefulWidget {
  final Project project;
  final ProjectGeneratorService projectService;
  final bool isChallengeMode;

  const IDEScreen({
    super.key,
    required this.project,
    required this.projectService,
    this.isChallengeMode = false,
  });

  @override
  State<IDEScreen> createState() => _IDEScreenState();
}

class _IDEScreenState extends State<IDEScreen> with TickerProviderStateMixin {
  late Project _project;
  bool _isLoading = true;
  String? _selectedFile;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = []; // {role, content}
  bool _isAgentTyping = false;
  late TabController _tabController;
  final CodeExecutionService _codeService = CodeExecutionService();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = 1; // Default to Code view
    _initializeProject();
  }

  Future<void> _initializeProject() async {
    if (_project.files.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _selectedFile = _project.files.keys.first;
        _codeController.text = _project.files[_selectedFile]!;
      });
      return;
    }

    try {
      final filledProject = await widget.projectService.populateProjectFiles(
        _project,
      );
      if (mounted) {
        setState(() {
          _project = filledProject;
          _isLoading = false;
          if (_project.files.isNotEmpty) {
            _selectedFile = _project.files.keys.first;
            _codeController.text = _project.files[_selectedFile]!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading project: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _onFileSelected(String filename) {
    setState(() {
      // Save current file changes
      if (_selectedFile != null) {
        _project.files[_selectedFile!] = _codeController.text;
      }

      _selectedFile = filename;
      _codeController.text = _project.files[filename] ?? '';
      _tabController.animateTo(1); // Switch to code view
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _chatController.clear();
      _isAgentTyping = true;
    });

    try {
      final response = await widget.projectService.getAgentAssistance(
        _project,
        _selectedFile ?? 'None',
        _codeController.text,
        text,
      );

      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'agent', 'content': response});
          _isAgentTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'system', 'content': 'Error: $e'});
          _isAgentTyping = false;
        });
      }
    }
  }

  Future<void> _runCode() async {
    // 1. Identify valid file to run
    String? codeToRun;
    String language = _project.language.toLowerCase();

    // Check if current file is runnable
    final ext =
        _selectedFile != null && _selectedFile!.contains('.')
            ? _selectedFile!.split('.').last
            : '';

    if (['py', 'js', 'dart', 'cpp', 'java'].contains(ext)) {
      codeToRun = _codeController.text;
    } else if (_project.files.keys.any((k) => k.startsWith('main'))) {
      // Fallback to main file match
      final mainFile = _project.files.keys.firstWhere(
        (k) => k.startsWith('main'),
      );
      codeToRun = _project.files[mainFile];
      // Adjust language if needed (heuristic)
      if (mainFile.endsWith('.py')) language = 'python';
      if (mainFile.endsWith('.js')) language = 'javascript';
      if (mainFile.endsWith('.dart')) language = 'dart';
      if (mainFile.endsWith('.cpp')) language = 'c++';
      if (mainFile.endsWith('.java')) language = 'java';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a runnable file (Python/JS/Dart/C++/Java) to execute.',
          ),
        ),
      );
      return;
    }

    // Check if the code needs input (simple heuristic)
    bool needsInput =
        codeToRun!.contains('input(') ||
        codeToRun.contains('stdin') ||
        codeToRun.contains('Scanner') ||
        codeToRun.contains('cin >>');

    String stdinInput = '';

    if (needsInput) {
      final inputController = TextEditingController();
      final shouldRun = await showDialog<bool>(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Program Input'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This program seems to require input. Enter it below (separate multiple inputs with new lines):',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: inputController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter input...',
                    prefixIcon: Icon(Icons.keyboard_rounded),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Run'),
              ),
            ],
          );
        },
      );

      if (shouldRun != true) return;
      stdinInput = inputController.text;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Compiling and Running...'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
    );

    try {
      final result = await _codeService.executeCode(
        language: language,
        code: codeToRun,
        stdin: stdinInput,
      );

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result['success']
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: result['success'] ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Output:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(0.2)),
                  ),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Text(
                      result['success']
                          ? (result['data']['output'] ?? 'No output')
                          : 'Error: ${result['error']}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (widget.isChallengeMode && result['success']) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.celebration_rounded),
                    label: const Text('Challenge Passed! Click to Finish'),
                  ),
                ],
              ],
            ),
          );
        },
      );

      // After sheet is closed, check if we should finish the challenge
      if (mounted && widget.isChallengeMode && result['success']) {
        Navigator.pop(context, true); // Return success to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Execution Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _project.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              '${_project.language} • ${_project.difficulty}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E1E1E), const Color(0xFF2D2D30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.folder_rounded), text: 'Files'),
            Tab(icon: Icon(Icons.code_rounded), text: 'Editor'),
            Tab(icon: Icon(Icons.smart_toy_rounded), text: 'AI Agent'),
          ],
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              onPressed: _runCode,
              tooltip: 'Run Project',
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 24),
                    const Text(
                      'Generating Project Structure...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildFileExplorer(),
                  _buildCodeEditor(),
                  _buildAgentChat(),
                ],
              ),
    );
  }

  Widget _buildFileExplorer() {
    return ListView.builder(
      itemCount: _project.files.length,
      itemBuilder: (context, index) {
        final filename = _project.files.keys.elementAt(index);
        final isSelected = filename == _selectedFile;

        IconData fileIcon;
        Color iconColor;

        if (filename.endsWith('.md')) {
          fileIcon = Icons.description_rounded;
          iconColor = Colors.blue.shade300;
        } else if (filename.endsWith('.py')) {
          fileIcon = Icons.code_rounded;
          iconColor = Colors.yellow.shade700;
        } else if (filename.endsWith('.js')) {
          fileIcon = Icons.javascript_rounded;
          iconColor = Colors.yellow.shade600;
        } else if (filename.endsWith('.dart')) {
          fileIcon = Icons.code_rounded;
          iconColor = Colors.blue.shade400;
        } else if (filename.endsWith('.java')) {
          fileIcon = Icons.coffee_rounded;
          iconColor = Colors.orange.shade700;
        } else if (filename.endsWith('.cpp')) {
          fileIcon = Icons.code_rounded;
          iconColor = Colors.purple.shade400;
        } else {
          fileIcon = Icons.insert_drive_file_rounded;
          iconColor = Colors.grey.shade400;
        }

        return Card(
          elevation: 0,
          color:
              isSelected
                  ? Colors.blueAccent.withOpacity(0.15)
                  : Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: Icon(fileIcon, color: iconColor),
            title: Text(
              filename,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            onTap: () => _onFileSelected(filename),
          ),
        );
      },
    );
  }

  Widget _buildCodeEditor() {
    if (_selectedFile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off_rounded, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No file selected', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          width: double.infinity,
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedFile!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: _codeController,
            maxLines: null,
            expands: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (val) {
              // Auto-save logic could go here
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgentChat() {
    return Column(
      children: [
        Expanded(
          child:
              _chatHistory.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          size: 64,
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ask the AI Agent for help!',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Get code suggestions, explanations, and debugging help',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final msg = _chatHistory[index];
                      final isUser = msg['role'] == 'user';
                      final isSystem = msg['role'] == 'system';

                      return Align(
                        alignment:
                            isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isUser
                                    ? LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Colors.blue.shade700,
                                      ],
                                    )
                                    : null,
                            color:
                                isUser
                                    ? null
                                    : (isSystem
                                        ? Colors.red.shade900.withOpacity(0.3)
                                        : Colors.grey[800]),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                isSystem
                                    ? Border.all(color: Colors.red.shade700)
                                    : null,
                          ),
                          child: Text(
                            msg['content']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        if (_isAgentTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Agent is typing...',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask the Agent...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    prefixIcon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.blue.shade700],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
