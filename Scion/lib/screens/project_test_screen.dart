import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectTestScreen extends StatefulWidget {
  const ProjectTestScreen({super.key});

  @override
  State<ProjectTestScreen> createState() => _ProjectTestScreenState();
}

class _ProjectTestScreenState extends State<ProjectTestScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    print('═══════════════════════════════════════════════════');
    print('🔵 [TEST_SCREEN] Loading ALL Projects');
    print('═══════════════════════════════════════════════════');
    
    setState(() => _isLoading = true);
    try {
      print('📥 Querying course_projects table...');
      print('   SELECT * FROM course_projects ORDER BY created_at DESC');
      
      // Fetch ALL projects from course_projects table
      final response = await _supabase
          .from('course_projects')
          .select('*')
          .order('created_at', ascending: false);

      print('✅ Query successful!');
      print('📊 Found ${(response as List).length} projects');
      
      if ((response as List).isNotEmpty) {
        print('📋 Project List:');
        for (var i = 0; i < (response as List).length; i++) {
          final p = response[i];
          print('   ${i + 1}. ${p['title']} (ID: ${p['id']}, Course: ${p['course_id']})');
        }
      } else {
        print('⚠️  No projects found in database!');
      }

      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        
        print('═══════════════════════════════════════════════════');
        print('🎉 Projects loaded successfully!');
        print('   Total: ${_projects.length}');
        print('═══════════════════════════════════════════════════');
      }
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR loading projects!');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace.toString());
      print('═══════════════════════════════════════════════════');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Test Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? const Center(
                  child: Text('No projects found in database'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          project['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Course ID: ${project['course_id']}'),
                            Text('Difficulty: ${project['difficulty_level']}'),
                            Text('GitHub: ${project['github_template_url'] ?? 'N/A'}'),
                            Text('Approved: ${project['is_approved']}'),
                            Text('ID: ${project['id']}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Projects Found'),
              content: Text('Total: ${_projects.length} projects'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        label: Text('Total: ${_projects.length}'),
        icon: const Icon(Icons.info),
      ),
    );
  }
}
