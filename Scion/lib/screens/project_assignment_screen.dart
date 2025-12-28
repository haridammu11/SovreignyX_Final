import 'package:flutter/material.dart';
import '../services/project_assignment_service.dart';

class ProjectAssignmentScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const ProjectAssignmentScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<ProjectAssignmentScreen> createState() => _ProjectAssignmentScreenState();
}

class _ProjectAssignmentScreenState extends State<ProjectAssignmentScreen> {
  final _assignmentService = ProjectAssignmentService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _assignmentService.getAssignmentStats(widget.courseId);
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _autoAssign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Assign Projects'),
        content: const Text(
          'This will randomly assign approved projects to all teams without projects. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isAssigning = true);

      final result = await _assignmentService.autoAssignProjectsToCourse(widget.courseId);

      setState(() => _isAssigning = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Assignment complete'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          _loadStats();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Assignment - ${widget.courseName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Cards
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Assignment Statistics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Teams',
                                  _stats['total_teams']?.toString() ?? '0',
                                  Icons.group,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'With Projects',
                                  _stats['teams_with_projects']?.toString() ?? '0',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Without Projects',
                                  _stats['teams_without_projects']?.toString() ?? '0',
                                  Icons.pending,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Available Projects',
                                  _stats['available_projects']?.toString() ?? '0',
                                  Icons.assignment,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Auto-Assign Button
                  if ((_stats['teams_without_projects'] ?? 0) > 0 &&
                      (_stats['available_projects'] ?? 0) > 0)
                    ElevatedButton.icon(
                      onPressed: _isAssigning ? null : _autoAssign,
                      icon: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _isAssigning
                            ? 'Assigning...'
                            : 'Auto-Assign Projects (AI)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'How It Works',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Company creates and approves projects\n'
                            '2. Students form teams (2-4 members)\n'
                            '3. Click "Auto-Assign" to randomly assign projects\n'
                            '4. Teams can view their assigned project\n'
                            '5. Teams collaborate and submit work',
                            style: TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning if no projects
                  if ((_stats['available_projects'] ?? 0) == 0)
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No approved projects available. Ask companies to create projects first!',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Success if all assigned
                  if ((_stats['teams_without_projects'] ?? 0) == 0 &&
                      (_stats['total_teams'] ?? 0) > 0)
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'All teams have been assigned projects!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
