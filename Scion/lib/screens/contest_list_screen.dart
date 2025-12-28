import 'package:flutter/material.dart';
import '../services/contest_service.dart';
import 'contest_solve_screen.dart';

class ContestListScreen extends StatefulWidget {
  const ContestListScreen({super.key});

  @override
  State<ContestListScreen> createState() => _ContestListScreenState();
}

class _ContestListScreenState extends State<ContestListScreen>
    with SingleTickerProviderStateMixin {
  final ContestService _service = ContestService();
  List<Map<String, dynamic>> _contests = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadContests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadContests() async {
    final contests = await _service.getContests();
    setState(() {
      _contests = contests;
      _isLoading = false;
    });
    _animationController.forward();
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

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.emoji_events;
      case 'medium':
        return Icons.trending_up;
      case 'hard':
        return Icons.whatshot;
      default:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Live Contests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.deepOrange.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.live_tv, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_contests.length} Active',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Colors.white,
            ],
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade100,
                              Colors.red.shade100,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Loading contests...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                : _contests.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade200,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Active Contests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new challenges!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadContests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contests.length,
                    itemBuilder: (context, index) {
                      final contest = _contests[index];
                      final difficulty = contest['difficulty'] ?? 'Medium';
                      final difficultyColor = _getDifficultyColor(difficulty);

                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.1,
                              (index * 0.1) + 0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
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
                                colors: [
                                  Colors.white,
                                  difficultyColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: difficultyColor.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: difficultyColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
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
                                        child: Icon(
                                          _getDifficultyIcon(difficulty),
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contest['title'] ??
                                                  'Untitled Contest',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        difficultyColor
                                                            .withOpacity(0.2),
                                                        difficultyColor
                                                            .withOpacity(0.1),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: difficultyColor
                                                          .withOpacity(0.5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    difficulty,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: difficultyColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.timer,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${contest['duration_minutes']} mins',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (contest['description'] != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      contest['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.people,
                                              size: 16,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${contest['participants'] ?? 0} joined',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              difficultyColor,
                                              difficultyColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          onPressed: () async {
                                            final result = await _service.joinContestWithResult(contest['id']);
                                            if (result['success'] && mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          ContestSolveScreen(
                                                            contest: contest,
                                                          ),
                                                ),
                                              );
                                            } else {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to join: ${result['error']}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('Join Contest'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
