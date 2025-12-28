import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import 'team_formation_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _courseService = CourseService();
  bool _isLoading = true;
  bool _isEnrolling = false;
  bool _isEnrolled = false;
  bool _isCompleted = false;
  bool _isCompleting = false;

  List<Module> _modules = [];
  Map<int, List<Lesson>> _moduleLessons = {};

  // Current playing video
  YoutubePlayerController? _controller;
  Lesson? _currentLesson;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadCourseContent();
  }

  Future<void> _loadCourseContent() async {
    try {
      final modules = await _courseService.getModules(widget.courseId);

      // Load lessons for each module
      for (final module in modules) {
        final lessons = await _courseService.getLessons(module.id);
        _moduleLessons[module.id] = lessons;
      }

      // Check enrollment and completion status
      final enrollments = await _courseService.getUserEnrollments();
      final enrollment = enrollments.cast<Enrollment?>().firstWhere(
        (e) => e?.courseId == widget.courseId,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _modules = modules;
          _isEnrolled = enrollment != null;
          _isCompleted = enrollment != null && enrollment.progress == 100;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading course: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      await _courseService.enrollInCourse(widget.courseId);
      if (mounted) {
        setState(() {
          _isEnrolled = true;
          _isEnrolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Enrolled successfully! Start learning now.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnrolling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error enrolling: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeCourse() async {
    setState(() => _isCompleting = true);
    try {
      await _courseService.completeCourse(widget.courseId);
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _isCompleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🎉 Course Completed! You have been awarded points.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.amber.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error completing course: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _playLesson(Lesson lesson) {
    if (!_isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Please enroll in the course to watch lessons.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (lesson.videoUrl == null || lesson.videoUrl!.isEmpty) return;

    final videoId = YoutubePlayer.convertUrlToId(lesson.videoUrl!);
    if (videoId == null) return;

    if (_controller != null) {
      _controller!.load(videoId);
    } else {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    }

    setState(() {
      _currentLesson = lesson;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            if (_isEnrolled)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? Colors.green.withOpacity(0.2)
                          : cs.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isCompleted
                            ? Colors.green
                            : cs.primary.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCompleted ? Icons.check_circle : Icons.school,
                          size: 12,
                          color: _isCompleted ? Colors.green : cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCompleted ? 'Completed' : 'Enrolled',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isCompleted ? Colors.green : cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          if (_isEnrolled)
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Team Formation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamFormationScreen(
                      courseId: widget.courseId.toString(),
                      courseName: widget.courseTitle,
                    ),
                  ),
                );
              },
            ),
          if (_isEnrolled && !_isCompleted)
            IconButton(
              icon: _isCompleting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: cs.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              tooltip: 'Mark as Complete',
              onPressed: _isCompleting ? null : _completeCourse,
            ),
          if (_isCompleted)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Video Player Section
                if (_currentLesson != null && _controller != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: YoutubePlayerBuilder(
                      player: YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: cs.primary,
                      ),
                      builder: (context, player) {
                        return Column(
                          children: [
                            player,
                            Container(
                              color: cs.surfaceContainer,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_filled,
                                        color: cs.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _currentLesson!.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Custom Content Renderer
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _currentLesson!.content
                                        .split('\n')
                                        .map((line) {
                                      if (line.contains('| http')) {
                                        final parts = line.split('|');
                                        final title = parts[0].trim();
                                        final url = parts
                                            .sublist(1)
                                            .join('|')
                                            .trim();
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: cs.primary
                                                    .withOpacity(0.3)),
                                          ),
                                          child: InkWell(
                                            onTap: () async {
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.link,
                                                      color: cs.primary,
                                                      size: 20),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                        color: cs.primary,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationColor:
                                                            cs.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(Icons.open_in_new,
                                                      color: cs.primary,
                                                      size: 16),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.0),
                                        child: Text(
                                          line,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: cs.onSurfaceVariant),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // Enrolled/Not Enrolled Banner
                if (!_isEnrolled)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.2),
                          cs.surfaceContainerHighest
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.school, size: 48, color: cs.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Enroll to Start Learning',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get access to all ${_modules.length} modules and video lessons.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isEnrolling ? null : _enroll,
                            icon: _isEnrolling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.rocket_launch),
                            label: Text(_isEnrolling
                                ? 'Enrolling...'
                                : 'Enroll Now'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Modules List
                Expanded(
                  child: _modules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library_outlined,
                                  size: 64, color: cs.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                'No modules available',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _modules.length,
                          itemBuilder: (context, index) {
                            final module = _modules[index];
                            final lessons = _moduleLessons[module.id] ?? [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: cs.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: cs.outline.withOpacity(0.1)),
                              ),
                              child: Theme(
                                data: theme.copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.all(16),
                                  collapsedIconColor: cs.onSurfaceVariant,
                                  iconColor: cs.primary,
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    module.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${lessons.length} lessons',
                                    style:
                                        TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                  initiallyExpanded: index == 0,
                                  children: lessons.map((lesson) {
                                    final isSelected =
                                        _currentLesson?.id == lesson.id;
                                    return Container(
                                      margin: const EdgeInsets.fromLTRB(
                                          8, 0, 8, 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cs.primary.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(
                                                color:
                                                    cs.primary.withOpacity(0.5))
                                            : null,
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.play_circle_outline,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurfaceVariant,
                                        ),
                                        title: Text(
                                          lesson.title,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? cs.primary
                                                : cs.onSurface,
                                          ),
                                        ),
                                        trailing: _isEnrolled
                                            ? Icon(Icons.lock_open,
                                                size: 16,
                                                color: cs.secondary)
                                            : Icon(Icons.lock,
                                                size: 16,
                                                color: cs.outline),
                                        onTap: () => _playLesson(lesson),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
