import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../services/course_service.dart';

class ProgressTrackingScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const ProgressTrackingScreen({super.key, required this.userId, this.token});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  late CourseService _courseService;
  List<Enrollment> _enrollments = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      // Load user enrollments
      final enrollments = await _courseService.getUserEnrollments();

      // Load course details for each enrollment
      List<Course> courses = [];
      for (var enrollment in enrollments) {
        try {
          final course = await _courseService.getCourse(enrollment.courseId);
          courses.add(course);
        } catch (e) {
          print('Failed to load course ${enrollment.courseId}: $e');
        }
      }

      setState(() {
        _enrollments = enrollments;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load progress data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProgressData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadProgressData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Learning streak
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 40,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Learning Streak',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_userProfile?.streak ?? 0} days in a row',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    // Continue learning action
                                  },
                                  child: const Text('Continue'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Overall progress
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Overall Progress',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Progress chart placeholder
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text('Progress Chart Visualization'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _ProgressStat(
                                      icon: Icons.school,
                                      label: 'Courses',
                                      value: '5',
                                    ),
                                    _ProgressStat(
                                      icon: Icons.quiz,
                                      label: 'Quizzes',
                                      value: '12',
                                    ),
                                    _ProgressStat(
                                      icon: Icons.assignment,
                                      label: 'Assignments',
                                      value: '8',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Course progress
                        const Text(
                          'Course Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_enrollments.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'You are not enrolled in any courses yet.',
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _enrollments.length,
                            itemBuilder: (context, index) {
                              final enrollment = _enrollments[index];
                              final course = _courses.firstWhere(
                                (c) => c.id == enrollment.courseId,
                                orElse:
                                    () => Course(
                                      id: enrollment.courseId,
                                      title: 'Unknown Course',
                                      description: '',
                                      categoryId: 0,
                                      instructorId: 0,
                                      price: 0,
                                      isPublished: false,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Progress bar
                                      LinearProgressIndicator(
                                        value: enrollment.progress / 100,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${enrollment.progress.toStringAsFixed(1)}% Complete',
                                          ),
                                          if (enrollment.completedAt != null)
                                            const Text(
                                              'Completed',
                                              style: TextStyle(
                                                color: Colors.green,
                                              ),
                                            )
                                          else
                                            TextButton(
                                              onPressed: () {
                                                // Resume course action
                                              },
                                              child: const Text('Resume'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 20),

                        // Achievements
                        const Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5, // Placeholder for achievements
                            itemBuilder: (context, index) {
                              return Card(
                                margin: const EdgeInsets.only(right: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        index == 0
                                            ? Icons.emoji_events
                                            : Icons.emoji_events_outlined,
                                        color:
                                            index == 0
                                                ? Colors.yellow
                                                : Colors.grey,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        index == 0 ? 'First Course' : 'Locked',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProgressStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
