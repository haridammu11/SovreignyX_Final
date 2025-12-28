import 'package:flutter/material.dart';

import '../models/social.dart';
import '../services/social_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String userId;
  final String? token;

  const LeaderboardScreen({super.key, required this.userId, this.token});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late SocialService _socialService;
  List<Leaderboard> _leaderboard = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _userRank = 0;
  int _userPoints = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final leaderboard = await _socialService.getLeaderboard();

      // Find user's rank and points
      final userEntry = leaderboard.firstWhere(
        (entry) => entry.userId == widget.userId,
        orElse:
            () => Leaderboard(
              id: 0,
              userId: widget.userId,
              points: 0,
              rank: 0,
              lastUpdated: DateTime.now(),
            ),
      );

      if (!mounted) return;
      setState(() {
        _leaderboard = leaderboard;
        _userRank = userEntry.rank;
        _userPoints = userEntry.points;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.emoji_events_rounded;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: cs.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadLeaderboard,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadLeaderboard,
                child: CustomScrollView(
                  slivers: [
                    // User's Rank Card
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRankColor(_userRank).withOpacity(0.2),
                              cs.primaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getRankColor(_userRank).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getRankColor(_userRank),
                                      _getRankColor(_userRank).withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRankColor(
                                        _userRank,
                                      ).withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child:
                                      _userRank <= 3
                                          ? Icon(
                                            _getRankIcon(_userRank),
                                            color: Colors.white,
                                            size: 32,
                                          )
                                          : Text(
                                            '$_userRank',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Rank',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.stars_rounded,
                                          size: 16,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$_userPoints points',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/achievements');
                                },
                                icon: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 18,
                                ),
                                label: const Text('Achievements'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top Learners Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          children: [
                            Icon(Icons.leaderboard_rounded, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Top Learners',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Leaderboard List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = _leaderboard[index];
                        final isUser = entry.userId == widget.userId;
                        final isTopThree = entry.rank <= 3;

                        return FadeTransition(
                          opacity: _animationController.drive(
                            CurveTween(curve: Curves.easeOut),
                          ),
                          child: SlideTransition(
                            position: _animationController.drive(
                              Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOut)),
                            ),
                            child: Card(
                              elevation: isTopThree ? 2 : 0,
                              color:
                                  isUser
                                      ? cs.secondaryContainer
                                      : (isTopThree
                                          ? _getRankColor(
                                            entry.rank,
                                          ).withOpacity(0.08)
                                          : cs.surfaceContainerHighest),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient:
                                        isTopThree
                                            ? LinearGradient(
                                              colors: [
                                                _getRankColor(entry.rank),
                                                _getRankColor(
                                                  entry.rank,
                                                ).withOpacity(0.7),
                                              ],
                                            )
                                            : null,
                                    color:
                                        isTopThree ? null : cs.primaryContainer,
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        isTopThree
                                            ? [
                                              BoxShadow(
                                                color: _getRankColor(
                                                  entry.rank,
                                                ).withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child: Center(
                                    child:
                                        isTopThree
                                            ? Icon(
                                              _getRankIcon(entry.rank),
                                              color: Colors.white,
                                              size: 24,
                                            )
                                            : Text(
                                              '${entry.rank}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: cs.onPrimaryContainer,
                                                fontSize: 16,
                                              ),
                                            ),
                                  ),
                                ),
                                title: Text(
                                  (entry.firstName != null &&
                                          entry.firstName!.isNotEmpty)
                                      ? '${entry.firstName} ${entry.lastName}'
                                          .trim()
                                      : (entry.username != null &&
                                          entry.username!.isNotEmpty)
                                      ? entry.username!
                                      : 'User ${entry.userId}',
                                  style: TextStyle(
                                    fontWeight:
                                        isUser
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'Updated ${entry.lastUpdated.day}/${entry.lastUpdated.month}/${entry.lastUpdated.year}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        isTopThree
                                            ? LinearGradient(
                                              colors: [
                                                _getRankColor(
                                                  entry.rank,
                                                ).withOpacity(0.2),
                                                _getRankColor(
                                                  entry.rank,
                                                ).withOpacity(0.1),
                                              ],
                                            )
                                            : null,
                                    color:
                                        isTopThree ? null : cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        size: 16,
                                        color:
                                            isTopThree
                                                ? _getRankColor(entry.rank)
                                                : cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.points}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color:
                                              isTopThree
                                                  ? _getRankColor(entry.rank)
                                                  : cs.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: _leaderboard.length),
                    ),

                    // How Ranking Works
                    SliverToBoxAdapter(
                      child: Card(
                        elevation: 0,
                        color: cs.surfaceContainerHighest,
                        margin: const EdgeInsets.all(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'How Ranking Works',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...[
                                (Icons.school_rounded, 'Complete courses'),
                                (Icons.quiz_rounded, 'Score high in quizzes'),
                                (
                                  Icons.forum_rounded,
                                  'Participate in discussions',
                                ),
                                (
                                  Icons.assignment_turned_in_rounded,
                                  'Submit assignments on time',
                                ),
                                (Icons.people_rounded, 'Help other learners'),
                                (
                                  Icons.local_fire_department_rounded,
                                  'Maintain learning streaks',
                                ),
                              ].map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.$1,
                                        size: 20,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.$2,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
