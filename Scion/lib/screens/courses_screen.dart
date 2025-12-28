import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadCourses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseService.getCourses();
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

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
            const Text(
              'Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!_isLoading && _courses.isNotEmpty)
              Text(
                '${_courses.length} courses available',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/course-search');
            },
            tooltip: 'Search Courses',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: cs.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: TextStyle(color: cs.onSurface)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: _courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined,
                                  size: 80, color: cs.onSurfaceVariant),
                              const SizedBox(height: 24),
                              Text(
                                'No Courses Available',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _courses.length,
                          itemBuilder: (context, index) {
                            final course = _courses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: cs.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: cs.outline.withOpacity(0.1)),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/course-detail',
                                    arguments: {
                                      'courseId': course.id,
                                      'courseTitle': course.title,
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.school,
                                          color: cs.onPrimaryContainer,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              course.description,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: cs.primary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'courses_fab',
        onPressed: () {
          Navigator.pushNamed(context, '/course-search');
        },
        backgroundColor: cs.primary,
        child: Icon(Icons.search, color: cs.onPrimary),
      ),
    );
  }
}
