import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/contest_service.dart';
import '../services/config_service.dart';
import 'code_editor_screen.dart';
import '../services/proctor_service.dart';
import '../models/gamification_challenge.dart';

class ContestSolveScreen extends StatefulWidget {
  final Map<String, dynamic> contest;

  const ContestSolveScreen({super.key, required this.contest});

  @override
  State<ContestSolveScreen> createState() => _ContestSolveScreenState();
}

class _ContestSolveScreenState extends State<ContestSolveScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ContestService _service = ContestService();
  List<Map<String, dynamic>> _codingProblems = [];
  List<Map<String, dynamic>> _quizQuestions = [];
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _animationController;
  Map<int, int?> _quizAnswers = {};

  // Proctoring service
  final ProctorService _proctorService = ProctorService();
  String? _studentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _generateQuestions();
    _initProctoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proctorService.stopSession(); // Stop proctoring when exiting contest
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _proctorService.recordEvent('TAB_SWITCH', description: 'User switched away from the app');
      _proctorService.pauseCapture();
    } else if (state == AppLifecycleState.inactive) {
      _proctorService.recordEvent('TAB_SWITCH', description: 'App focus lost (Overlay or System gesture)');
    } else if (state == AppLifecycleState.resumed) {
      _proctorService.recordEvent('TAB_SWITCH', description: 'User returned to the app');
      _proctorService.resumeCapture();
    }
  }

  Future<void> _initProctoring() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      _studentId = user?.email ?? 'anonymous_student';

      final success = await _proctorService.startSession(
        userId: _studentId!,
        contestId: widget.contest['id']?.toString() ?? 'contest_456',
      );

      if (success && mounted) {
        setState(() {}); // Trigger rebuild to show camera preview if needed
      }
    } catch (e) {
      debugPrint('Proctoring Init Error: $e');
    }
  }

  void _finishContest() async {
    // Calculate Score
    int score = 0;
    
    // Each correct quiz question = 20 points
    _quizQuestions.asMap().forEach((index, question) {
      if (_quizAnswers[index] == question['correct_answer_index']) {
        score += 20;
      }
    });

    // Bonus for participation
    score += 10;

    // Confirm Submission
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Contest?'),
        content: Text('Your calculated score is $score. Are you sure you want to finish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final success = await _service.submitContestResult(
                widget.contest['id'].toString(), 
                score
              );

              // ProctorService handles session cleanup automatically

              if (mounted) {
                setState(() => _isLoading = false);
                if (success) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Contest Completed!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                          const SizedBox(height: 16),
                          Text('Great job! Your final score is $score'),
                          const Text('\nYour result has been synchronized with the leaderboard.'),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Pop dialog
                            Navigator.pop(context); // Back to contest list
                          },
                          child: const Text('Finish'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to submit results. Please try again.')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuestions() async {
    final data = await _service.generateContestQuestions(
      widget.contest['title'],
      widget.contest['description'],
      widget.contest['difficulty'],
    );
    if (mounted) {
      setState(() {
        _codingProblems = List<Map<String, dynamic>>.from(
          data['coding_problems'] ?? [],
        );
        _quizQuestions = List<Map<String, dynamic>>.from(
          data['quiz_questions'] ?? [],
        );
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(
      widget.contest['difficulty'] ?? 'Medium',
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contest['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.timer, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${widget.contest['duration_minutes']} mins',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _proctorService.isActive ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _proctorService.isActive ? Colors.red : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_proctorService.isActive)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        _proctorService.isActive ? 'LIVE MONITORING' : 'OFFLINE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Finish Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: _finishContest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: difficultyColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [difficultyColor, difficultyColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.code),
              text: 'Coding (${_codingProblems.length})',
            ),
            Tab(
              icon: const Icon(Icons.quiz),
              text: 'Quiz (${_quizQuestions.length})',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Camera is managed by ProctorService, no preview needed here
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [difficultyColor.withOpacity(0.05), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child:
                _isLoading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              difficultyColor.withOpacity(0.2),
                              difficultyColor.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            difficultyColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'AI is generating contest content...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Creating challenging problems for you',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  controller: _tabController,
                  children: [
                    // CODING PROBLEMS TAB
                    _codingProblems.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.code_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No coding problems available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _codingProblems.length,
                          itemBuilder: (context, index) {
                            final q = _codingProblems[index];
                            return FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    index * 0.15,
                                    (index * 0.15) + 0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.2, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      index * 0.15,
                                      (index * 0.15) + 0.5,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        difficultyColor.withOpacity(0.03),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: difficultyColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: difficultyColor.withOpacity(
                                          0.15,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.all(16),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            16,
                                          ),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              difficultyColor,
                                              difficultyColor.withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        q['title'] ?? 'Problem ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          q['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.input,
                                                    size: 18,
                                                    color: difficultyColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Input Format:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                q['input_format'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.output,
                                                    size: 18,
                                                    color: difficultyColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'Output Format:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                q['output_format'] ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  difficultyColor,
                                                  difficultyColor.withOpacity(
                                                    0.8,
                                                  ),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: difficultyColor
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => CodeEditorScreen(
                                                          userId: _studentId ?? 'contest_user',
                                                          proctorSessionId: _proctorService.sessionId,
                                                          proctorBackendUrl: null, // Service handles this
                                                          challenge: GamificationChallenge(
                                                            description:
                                                                "${q['title']}\n\n${q['description']}\n\nInput Format: ${q['input_format']}\nOutput Format: ${q['output_format']}",
                                                            initialCode:
                                                                "# Write your solution here\n",
                                                            language: "python",
                                                            solutionCode: "",
                                                            testCases: List<
                                                              Map<
                                                                String,
                                                                dynamic
                                                              >
                                                            >.from(
                                                              q['test_cases'] ??
                                                                  [],
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.code),
                                              label: const Text('Solve in IDE'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                    // QUIZ TAB
                    _quizQuestions.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No quiz questions available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _quizQuestions.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final q = _quizQuestions[index];
                            final options = List<String>.from(
                              q['options'] ?? [],
                            );
                            final correctIndex = q['correct_answer_index'] ?? 0;

                            return FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    index * 0.1,
                                    (index * 0.1) + 0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue,
                                                  Colors.blue.shade700,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Q${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              q['question'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ...List.generate(options.length, (
                                        optIndex,
                                      ) {
                                        final isSelected =
                                            _quizAnswers[index] == optIndex;
                                        final isCorrect =
                                            optIndex == correctIndex;
                                        final showResult = isSelected;

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient:
                                                showResult
                                                    ? LinearGradient(
                                                      colors:
                                                          isCorrect
                                                              ? [
                                                                Colors
                                                                    .green
                                                                    .shade50,
                                                                Colors
                                                                    .green
                                                                    .shade100,
                                                              ]
                                                              : [
                                                                Colors
                                                                    .red
                                                                    .shade50,
                                                                Colors
                                                                    .red
                                                                    .shade100,
                                                              ],
                                                    )
                                                    : null,
                                            color:
                                                showResult
                                                    ? null
                                                    : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  showResult
                                                      ? (isCorrect
                                                          ? Colors.green
                                                          : Colors.red)
                                                      : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: RadioListTile<int>(
                                            value: optIndex,
                                            groupValue: _quizAnswers[index],
                                            activeColor:
                                                showResult
                                                    ? (isCorrect
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Colors.blue,
                                            onChanged: (val) {
                                              setState(() {
                                                _quizAnswers[index] = val;
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        val == correctIndex
                                                            ? Icons.check_circle
                                                            : Icons.cancel,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        val == correctIndex
                                                            ? '✓ Correct!'
                                                            : '✗ Wrong Answer',
                                                      ),
                                                    ],
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  backgroundColor:
                                                      val == correctIndex
                                                          ? Colors
                                                              .green
                                                              .shade700
                                                          : Colors.red.shade700,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                            title: Text(
                                              options[optIndex],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    showResult
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ), // End of Container
            ], // End of Stack
          ),
    );
  }
}
