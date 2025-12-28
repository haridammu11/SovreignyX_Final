import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'course_creation_screen.dart';
import 'project_management_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final response = await _client.from('courses').select('id, title, description').order('created_at', ascending: false);
      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseCreationScreen()),
          );
          _fetchCourses();
        },
        label: const Text('Create Course'),
        icon: const Icon(Icons.auto_awesome_rounded), // AI icon
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: theme.colorScheme.secondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No courses found',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {}, // Add logic or just use FAB
                        child: const Text('Tap "Create Course" to get started'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectManagementScreen(
                                courseId: course['id'].toString(),
                                courseTitle: course['title'],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.book_rounded, color: theme.colorScheme.onPrimaryContainer),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course['title'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Created recently', // Placeholder for date if needed
                                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: theme.hintColor),
                                ],
                              ),
                              if (course['description'] != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  course['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProjectManagementScreen(
                                            courseId: course['id'].toString(),
                                            courseTitle: course['title'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.assignment_rounded, size: 18),
                                    label: const Text('Manage Projects'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
