 import 'package:flutter/material.dart';
import '../services/course_service.dart';
import 'course_detail_screen.dart';

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CourseService _courseService = CourseService();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _searchCourse() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please enter a course topic');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _animationController.repeat();

    try {
      final results = await _courseService.searchCourses(query);

      if (results.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/course-detail',
          arguments: {
            'courseId': results.first.id,
            'courseTitle': results.first.title,
          },
        );
      } else {
        setState(() => _errorMessage = 'No courses found for "$query".');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Search failed: $e');
    } finally {
      _animationController.stop();
      _animationController.reset();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Search Courses',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Search Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search,
                  size: 64,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Find Your Course',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for courses by topic or keyword',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              // Search Field
              TextField(
                controller: _searchController,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Course Topic',
                  hintText: 'e.g., Flutter, Python, Machine Learning',
                  prefixIcon: Icon(Icons.school, color: cs.primary),
                  suffixIcon: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: RotationTransition(
                            turns: _animationController,
                            child: Icon(Icons.refresh, color: cs.primary),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.search, color: cs.primary),
                          onPressed: _searchCourse,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _searchCourse(),
              ),
              const SizedBox(height: 24),
              // Search Button
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _searchCourse,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _isLoading ? 'Searching...' : 'Search Courses',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
