import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/social_service.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;
  final String? token;

  const AchievementsScreen({super.key, required this.userId, this.token});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late SocialService _socialService;
  late AnimationController _animationController;
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadAchievements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _socialService.getAchievements(widget.userId);
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load achievements: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAchievements,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadAchievements,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Achievement stats with gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _AchievementStat(
                                    icon: Icons.emoji_events,
                                    label: 'Total',
                                    value: '${_achievements.length}',
                                    color: Colors.amber,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  _AchievementStat(
                                    icon: Icons.star,
                                    label: 'Points',
                                    value: '${_calculateTotalPoints()}',
                                    color: Colors.yellowAccent,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  _AchievementStat(
                                    icon: Icons.trending_up,
                                    label: 'Rank',
                                    value: '#${_calculateRank()}',
                                    color: Colors.lightGreenAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Achievements grid header
                          Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Achievements',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_achievements.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No achievements yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Keep learning to earn badges!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: _achievements.length + 5,
                              itemBuilder: (context, index) {
                                if (index < _achievements.length) {
                                  final achievement = _achievements[index];
                                  return _AchievementCard(
                                    achievement: achievement,
                                    index: index,
                                    animation: _animationController,
                                  );
                                } else {
                                  return _LockedAchievementCard(index: index);
                                }
                              },
                            ),

                          const SizedBox(height: 32),

                          // Achievement categories
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _CategoryChip(
                                label: 'Course Completion',
                                icon: Icons.school,
                                color: Colors.blue,
                              ),
                              _CategoryChip(
                                label: 'Quiz Master',
                                icon: Icons.quiz,
                                color: Colors.purple,
                              ),
                              _CategoryChip(
                                label: 'Streak Keeper',
                                icon: Icons.local_fire_department,
                                color: Colors.orange,
                              ),
                              _CategoryChip(
                                label: 'Community Helper',
                                icon: Icons.people,
                                color: Colors.green,
                              ),
                              _CategoryChip(
                                label: 'Early Bird',
                                icon: Icons.wb_sunny,
                                color: Colors.amber,
                              ),
                              _CategoryChip(
                                label: 'Night Owl',
                                icon: Icons.nightlight_round,
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  int _calculateTotalPoints() {
    return _achievements.length * 100;
  }

  int _calculateRank() {
    return 15;
  }
}

class _AchievementStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AchievementStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final int index;
  final AnimationController animation;

  const _AchievementCard({
    required this.achievement,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeIn),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Show achievement details
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.amber.shade600,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        achievement.icon != null
                            ? Icons.emoji_events
                            : Icons.emoji_events_outlined,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      achievement.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${achievement.earnedAt.day}/${achievement.earnedAt.month}/${achievement.earnedAt.year}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedAchievementCard extends StatelessWidget {
  final int index;

  const _LockedAchievementCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 36,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Locked',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete more courses\nto unlock',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Filter by category
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
