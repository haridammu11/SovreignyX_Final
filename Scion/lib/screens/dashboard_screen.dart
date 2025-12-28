import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/user.dart';
import '../models/project_model.dart';
import '../services/auth_service.dart';
import '../services/daily_task_service.dart';
import 'follow_requests_screen.dart';
import 'user_search_screen.dart';
import '../widgets/recommendations_widget.dart';
import 'courses_screen.dart';
import 'social_feed_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;

  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _isLoading = true;

  // Material 3 NavigationBar index
  int _currentIndex = 0;

  // Dynamic stats
  int _enrolledCourses = 0;
  int _achievements = 0;
  int _rank = 0;
  int _streak = 0;

  // Daily Tasks
  final DailyTaskService _dailyTaskService = DailyTaskService();
  Map<String, dynamic>? _todaysTasks;
  bool _isDailyTasksLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDailyTasks();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await widget.authService.getUserProfile();
      final statsResult = await widget.authService.getDashboardStats();

      int dynamicStreak = 0;
      final currentUser = widget.authService.currentUser;
      if (currentUser != null) {
        dynamicStreak = await _dailyTaskService.calculateStreak(currentUser.id);
      }

      if (!mounted) return;
      setState(() {
        if (result['success'] == true) {
          _user = currentUser;
        }

        if (statsResult['success'] == true) {
          final stats = statsResult['data'] ?? {};
          _enrolledCourses = stats['courses'] ?? 0;
          _achievements = stats['achievements'] ?? 0;
          _rank = stats['rank'] ?? 0;
          _streak = dynamicStreak;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // ignore: avoid_print
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadDailyTasks() async {
    setState(() => _isDailyTasksLoading = true);
    try {
      final tasks = await _dailyTaskService.getTodaysTasks();

      if (!mounted) return;
      setState(() {
        _todaysTasks = tasks;
        _isDailyTasksLoading = false;
      });

      // Auto-sync streak status
      if (tasks != null) {
        final date = tasks['date'];
        final uid = tasks['user_id'];
        if (uid != null && date != null) {
          await _dailyTaskService.syncDailyCompletion(uid, date);
          if (mounted) await _loadUserData();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading daily tasks: $e');
      if (mounted) setState(() => _isDailyTasksLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadUserData(), _loadDailyTasks()]);
  }

  void _logout() async {
    await widget.authService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  // ---------------- Daily Tasks ----------------

  void _openCodeChallenge() async {
    if (_todaysTasks == null) return;
    final challenge = _todaysTasks!['challenge_data'] ?? {};
    final isDone = _todaysTasks!['challenge_completed'] ?? false;

    // Create Temporary Project
    String ext = 'py';
    final lang = (challenge['language'] ?? 'python').toString().toLowerCase();
    if (lang.contains('java')) {
      ext = 'java';
    } else if (lang.contains('c++')) {
      ext = 'cpp';
    } else if (lang.contains('dart')) {
      ext = 'dart';
    } else if (lang.contains('javascript')) {
      ext = 'js';
    }

    final project = Project(
      id: 'daily_${DateTime.now().toIso8601String()}',
      title: challenge['title'] ?? 'Daily Challenge',
      description: challenge['description'] ?? 'Solve the challenge',
      difficulty: 'Daily',
      language: challenge['language'] ?? 'Python',
      objectives: const ['Pass the challenge'],
      files: {'main.$ext': challenge['starter_code'] ?? 'print("Hello")'},
    );

    final result = await Navigator.pushNamed(
      context,
      '/ide',
      arguments: {'project': project, 'isChallengeMode': !isDone},
    );

    if (result == true && !isDone) {
      await _dailyTaskService.updateTaskStatus('challenge', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge Passed! Streak updated.')),
        );
      }
      _refreshData();
    }
  }

  void _openQuiz() {
    if (_todaysTasks == null) return;

    List quizData =
        (_todaysTasks!['quiz_data'] is List) ? _todaysTasks!['quiz_data'] : [];
    final isDone = _todaysTasks!['quiz_completed'] ?? false;

    if (isDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already completed the daily quiz!')),
      );
      return;
    }

    if (quizData.isEmpty || quizData[0]['options'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI unavailable. Loading backup quiz...')),
      );
      quizData = _dailyTaskService.getFallbackQuiz();
    }

    int currentQuestion = 0;
    int score = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final question = quizData[currentQuestion];
              final options =
                  (question['options'] is List)
                      ? (question['options'] as List)
                      : const [];

              return AlertDialog(
                title: Text(
                  'Question ${currentQuestion + 1}/${quizData.length}',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(question['question'] ?? 'Error loading question'),
                      const SizedBox(height: 14),
                      if (options.isEmpty)
                        const Text('No options available.')
                      else
                        ...List.generate(options.length, (index) {
                          return Card(
                            elevation: 0,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            child: ListTile(
                              title: Text(options[index].toString()),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                if (index ==
                                    (question['correct_index'] ?? -1)) {
                                  score++;
                                }
                                if (currentQuestion < quizData.length - 1) {
                                  setState(() => currentQuestion++);
                                } else {
                                  Navigator.pop(context);
                                  _finishQuiz(score, quizData.length);
                                }
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _finishQuiz(int score, int total) {
    final passed = score >= (total * 0.6);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(passed ? 'Quiz Passed!' : 'Try Again Tomorrow'),
            content: Text('You scored $score/$total.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (passed) {
                    await _dailyTaskService.updateTaskStatus('quiz', true);
                    _refreshData();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _openBrainGame() {
    if (_todaysTasks == null) return;

    final game = _todaysTasks!['brain_game_data'] ?? {};
    final isDone = _todaysTasks!['game_completed'] ?? false;

    if (isDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already solved today\'s puzzle!')),
      );
      return;
    }

    final rawAnswer = game['answer'] ?? game['solution'] ?? 'FLUTTER';
    final String answer = rawAnswer.toString().toUpperCase().trim();
    final String hint = (game['hint'] ?? 'No hint available').toString();

    String input = "";
    bool hintUsed = false;
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final cs = Theme.of(context).colorScheme;

              return AlertDialog(
                title: const Text('Word Puzzle'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game['question'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(answer.length, (index) {
                          final isHintChar =
                              hintUsed &&
                              (index == 0 || index == answer.length - 1);
                          final displayChar =
                              (index < input.length)
                                  ? input[index]
                                  : (isHintChar ? answer[index] : "");

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 36,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.5),
                              ),
                              color:
                                  (isHintChar && index >= input.length)
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHighest,
                            ),
                            child: Text(
                              displayChar,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z]'),
                          ),
                        ],
                        maxLength: answer.length,
                        decoration: const InputDecoration(
                          hintText: 'Type answer',
                          counterText: "",
                          prefixIcon: Icon(Icons.keyboard),
                        ),
                        onChanged:
                            (val) => setState(() => input = val.toUpperCase()),
                      ),

                      const SizedBox(height: 8),
                      if (!hintUsed)
                        TextButton.icon(
                          onPressed: () => setState(() => hintUsed = true),
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text('Use hint (reveals first/last)'),
                        )
                      else ...[
                        Text(
                          'Hint: $hint',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              input = answer;
                              controller.text = answer;
                            });
                          },
                          child: Text(
                            'Give up & show answer',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final cleanInput = input.trim().toUpperCase();
                      if (cleanInput == answer) {
                        await _dailyTaskService.updateTaskStatus('game', true);
                        if (context.mounted) Navigator.pop(context);
                        _refreshData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Correct! +1 brain power.'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Incorrect. Length: ${cleanInput.length}/${answer.length}. Keep trying!',
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showStreakCalendar() async {
    final dates = await _dailyTaskService.getStreakCalendar();

    // String normalization for reliable comparison
    final completedDays =
        dates
            .map(
              (d) =>
                  "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
            )
            .toSet();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;

        Widget dayChip(DateTime day, {required Color bg, required Color fg}) {
          return Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(
              '${day.day}',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          );
        }

        return AlertDialog(
          title: const Text('Streak Calendar'),
          content: SizedBox(
            width: 320,
            height: 380,
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(formatButtonVisible: false),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final dStr =
                      "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                  if (completedDays.contains(dStr)) {
                    return dayChip(day, bg: Colors.green, fg: Colors.white);
                  }
                  return null;
                },
                todayBuilder: (context, day, focusedDay) {
                  final dStr =
                      "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                  final isCompleted = completedDays.contains(dStr);
                  return dayChip(
                    day,
                    bg:
                        isCompleted
                            ? Colors.green
                            : cs.primary.withOpacity(0.55),
                    fg: Colors.white,
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ---------------- UI ----------------

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeroCard(
                    name: _user?.firstName ?? 'User',
                    email: _user?.email ?? '',
                    streak: _streak,
                    onTapStreak: _showStreakCalendar,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your stats',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.school_rounded,
                        title: 'Courses',
                        value: '$_enrolledCourses',
                        subtitle: 'Enrolled',
                        tint: cs.primaryContainer,
                      ),
                      _StatItem(
                        icon: Icons.emoji_events_rounded,
                        title: 'Achievements',
                        value: '$_achievements',
                        subtitle: 'Earned',
                        tint: cs.secondaryContainer,
                      ),
                      _StatItem(
                        icon: Icons.leaderboard_rounded,
                        title: 'Rank',
                        value: _rank > 0 ? '#$_rank' : 'N/A',
                        subtitle: 'Leaderboard',
                        tint: cs.tertiaryContainer,
                      ),
                      _StatItem(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Streak',
                        value: '$_streak',
                        subtitle: 'Days',
                        tint: Colors.orange.withOpacity(0.18),
                        onTap: _showStreakCalendar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const RecommendationsWidget(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Daily tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadDailyTasks,
                        tooltip: 'Reload tasks',
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              child: _buildDailyTasksBlock(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text(
                'Scion',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: cs.primary, // Cyan Logo-like text
                ),
              ),
              backgroundColor: cs.surface, // Black
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search Users',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserSearchScreen(authService: widget.authService),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  tooltip: 'Follow Requests',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowRequestsScreen(
                            authService: widget.authService),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            )
          : null,
      drawer: _currentIndex == 0
          ? _DashboardDrawer(user: _user, authService: widget.authService)
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const CoursesScreen(),
          SocialFeedScreen(
            userId: _user?.id ?? '',
            token: widget.authService.token,
          ),
          ProfileScreen(authService: widget.authService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.school_rounded), label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.groups_rounded), label: 'Social'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDailyTasksBlock(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isDailyTasksLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_todaysTasks == null) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text('Failed to load tasks. Pull to refresh.'),
        ),
      );
    }

    final allDone = _todaysTasks!['all_completed'] ?? false;

    return Column(
      children: [
        _TaskCard(
          icon: Icons.code_rounded,
          title: 'Code Challenge',
          subtitle: 'Solve a random coding problem',
          isDone: _todaysTasks!['challenge_completed'] ?? false,
          onTap: _openCodeChallenge,
        ),
        _TaskCard(
          icon: Icons.quiz_rounded,
          title: 'Daily Quiz',
          subtitle: '5 questions to test your knowledge',
          isDone: _todaysTasks!['quiz_completed'] ?? false,
          onTap: _openQuiz,
        ),
        _TaskCard(
          icon: Icons.psychology_rounded,
          title: 'Brain Training',
          subtitle: 'Solve today’s puzzle',
          isDone: _todaysTasks!['game_completed'] ?? false,
          onTap: _openBrainGame,
        ),
        if (allDone) ...[
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            color: Colors.green.withOpacity(0.12),
            child: const ListTile(
              leading: Icon(Icons.check_circle_rounded, color: Colors.green),
              title: Text(
                'All Daily Tasks Completed!',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Streak +1'),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------- Reusable UI widgets ----------------

class _DashboardDrawer extends StatelessWidget {
  final User? user;
  final AuthService authService;

  const _DashboardDrawer({required this.user, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.firstName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(
                (user?.firstName?.isNotEmpty ?? false)
                    ? user!.firstName![0].toUpperCase()
                    : 'U',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'authService': authService},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_rounded),
            title: const Text('My Courses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/courses');
            },
          ),
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('Search Courses'),
            onTap: () {
              Navigator.pushNamed(context, '/course-search');
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_rounded),
            title: const Text('Job Board'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/job-board');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_ind_rounded),
            title: const Text('My Applications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-applications');
            },
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard_rounded),
            title: const Text('Leaderboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/leaderboard',
                arguments: {'userId': user?.id},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.rss_feed_rounded),
            title: const Text('Social Feed'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/social-feed',
                arguments: {'userId': user?.id},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Progress'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/progress-tracking',
                arguments: {'userId': user?.id},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_rounded),
            title: const Text('AI Chat'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/aichat',
                arguments: {'userId': user?.id},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Live Contests'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contests');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library_rounded),
            title: const Text('Learning Reels'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reels');
            },
          ),
          ListTile(
            leading: const Icon(Icons.web_rounded),
            title: const Text('Web Page Generator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/web-generator');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('AI Course Generator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ai-course-generator');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Privacy Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/privacy-settings',
                arguments: {'userId': user?.id},
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String name;
  final String email;
  final int streak;
  final VoidCallback onTapStreak;

  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.streak,
    required this.onTapStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: cs.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $name',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTapStreak,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded),
                    const SizedBox(height: 2),
                    Text(
                      '$streak',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color tint;
  final VoidCallback? onTap;

  _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
    this.onTap,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

        final card = Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  item.tint.withOpacity(0.55),
                  cs.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: cs.onSurface),
                const Spacer(),
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        if (item.onTap == null) return card;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: item.onTap,
          child: card,
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;

  const _TaskCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone ? Colors.green : cs.primaryContainer,
          foregroundColor: isDone ? Colors.white : cs.onPrimaryContainer,
          child: Icon(isDone ? Icons.check_rounded : icon),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing:
            isDone
                ? Chip(
                  label: const Text('Done'),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  backgroundColor: Colors.green.withOpacity(0.16),
                  side: BorderSide(color: Colors.green.withOpacity(0.30)),
                )
                : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
