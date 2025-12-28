import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_course_service.dart';
import '../services/company_service.dart';
import 'login_screen.dart';

class ProjectManagementScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const ProjectManagementScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<ProjectManagementScreen> createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  final CompanyService _companyService = CompanyService();
  List<Map<String, dynamic>> _existingProjects = [];
  List<Map<String, dynamic>> _generatedIdeas = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  final TextEditingController _defaultGithubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await _companyService.getCourseProjects(widget.courseId);
    setState(() {
      _existingProjects = projects;
      _isLoading = false;
    });
  }

  Future<void> _generateIdeas() async {
    setState(() => _isGenerating = true);
    
    // Clear previous
    setState(() => _generatedIdeas = []);

    try {
      final ideas = await AiCourseService.generateProjectIdeas(widget.courseTitle);
      if (mounted) {
        setState(() => _generatedIdeas = ideas);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating ideas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> idea) {
    final TextEditingController githubController = TextEditingController(text: _defaultGithubController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Project: ${idea['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(idea['description'] ?? ''),
            const SizedBox(height: 16),
            TextField(
              controller: githubController,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository URL',
                hintText: 'https://github.com/company/course-project-template',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (githubController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter GitHub URL')),
                );
                return;
              }
              
              Navigator.pop(context); // Close dialog
              await _approveProject(idea, githubController.text);
            },
            child: const Text('Approve & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProject(Map<String, dynamic> idea, String githubUrl) async {
    // Check Auth
    if (Supabase.instance.client.auth.currentUser == null) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Session expired. Redirecting to Login...')),
         );
         Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false
         );
       }
       return;
    }

    setState(() => _isLoading = true);
    
    final success = await _companyService.saveCourseProject(
      courseId: widget.courseId,
      title: idea['title'],
      description: idea['description'] ?? '',
      difficulty: idea['difficulty'] ?? 'intermediate',
      githubUrl: githubUrl,
    );

    if (success) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project Approved and Saved!')),
        );
        setState(() {
           _generatedIdeas.remove(idea);
        });
        _loadProjects();
      }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save project.')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProjects,
            )
        ],
      ),
      body: Row(
        children: [
           // Left Panel: Existing Projects
           Expanded(
             flex: 1,
             child: Card(
               margin: const EdgeInsets.all(12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               child: Column(
                 children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Approved Course Projects', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                        child: _isLoading 
                        ? const Center(child: CircularProgressIndicator()) 
                        : _existingProjects.isEmpty 
                            ? Center(child: Text('No projects yet.', style: TextStyle(color: theme.hintColor)))
                            : ListView.builder(
                                itemCount: _existingProjects.length,
                                itemBuilder: (context, index) {
                                    final p = _existingProjects[index];
                                    return ListTile(
                                        title: Text(p['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(p['difficulty_level'] ?? ''),
                                        trailing: Icon(Icons.check_circle, color: theme.colorScheme.secondary),
                                        onTap: () {
                                            // Show details?
                                        },
                                    );
                                },
                            ),
                    ),
                 ],
               ),
             ),
           ),
           
           // Right Panel: Generator
           Expanded(
             flex: 1,
             child: Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                    children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text('AI Project Generator', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _defaultGithubController,
                                decoration: const InputDecoration(
                                  labelText: 'Default GitHub Template URL (Optional)',
                                  hintText: 'Enter URL to pre-fill for new projects',
                                  prefixIcon: Icon(Icons.link),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                    onPressed: _isGenerating ? null : _generateIdeas,
                                    icon: _isGenerating 
                                       ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                       : const Icon(Icons.auto_awesome),
                                    label: const Text('Generate AI Project Ideas'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(indent: 16, endIndent: 16, color: theme.dividerColor),
                        Expanded(
                            child: _generatedIdeas.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lightbulb_outline, size: 48, color: theme.disabledColor),
                                        const SizedBox(height: 8),
                                        Text('No active suggestions', style: TextStyle(color: theme.disabledColor)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _generatedIdeas.length,
                                    itemBuilder: (context, index) {
                                        final idea = _generatedIdeas[index];
                                        return Card(
                                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                            elevation: 0,
                                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            child: ListTile(
                                                title: Text(idea['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        const SizedBox(height: 4),
                                                        Text('Difficulty: ${idea['difficulty']}', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 4),
                                                        Text(idea['description'] ?? ''),
                                                    ],
                                                ),
                                                trailing: FilledButton(
                                                    onPressed: () => _showApprovalDialog(idea),
                                                    style: FilledButton.styleFrom(
                                                      visualDensity: VisualDensity.compact,
                                                      backgroundColor: theme.colorScheme.tertiary,
                                                    ),
                                                    child: const Text('Approve'),
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
        ],
      ),
    );
  }
}
