import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/web_page_generator_service.dart';
import 'live_web_editor_screen.dart';

class WebPageGeneratorScreen extends StatefulWidget {
  const WebPageGeneratorScreen({super.key});

  @override
  State<WebPageGeneratorScreen> createState() => _WebPageGeneratorScreenState();
}

class _WebPageGeneratorScreenState extends State<WebPageGeneratorScreen> {
  bool _isGenerating = false;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoadingProjects = false;

  final _promptController = TextEditingController();
  String _selectedTheme = 'dark';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final result = await WebPageGeneratorService.listProjects();
      if (result['success'] == true) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(result['projects']);
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _generatePage(
    String pageType,
    Map<String, dynamic> template,
  ) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await WebPageGeneratorService.createPage(
        pageType: template['pageType'],
        fields: List<Map<String, dynamic>>.from(template['fields']),
        theme: 'dark',
        validationRules:
            template['validationRules'] != null
                ? Map<String, String>.from(template['validationRules'])
                : null,
        projectName: '${pageType.toUpperCase()} Page',
      );

      if (result['success'] == true && mounted) {
        final webUrl = result['web_url'];
        final projectId = result['project_id'];

        // Reload projects list
        await _loadProjects();

        // Show success dialog
        _showSuccessDialog(webUrl, projectId);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${result['error']}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generateFromPrompt() async {
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the page you want to create'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await WebPageGeneratorService.generateFromPrompt(
        prompt: prompt,
        theme: _selectedTheme,
        projectName: 'Custom Page',
      );

      if (result['success'] == true && mounted) {
        final webUrl = result['web_url'];
        final projectId = result['project_id'];

        // Clear prompt
        _promptController.clear();

        // Reload projects list
        await _loadProjects();

        // Show success dialog
        _showSuccessDialog(webUrl, projectId);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${result['error']}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _showSuccessDialog(String webUrl, String projectId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Page Generated! 🚀'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your web page is live and ready to use!'),
                const SizedBox(height: 16),
                const Text(
                  'URL:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    webUrl,
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Project ID: $projectId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => LiveWebEditorScreen(
                            projectId: projectId,
                            webUrl: webUrl,
                            projectName: 'Generated Page',
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Live Editor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(webUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Browser'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _deletePage(String projectId) async {
    final result = await WebPageGeneratorService.deletePage(projectId);
    if (result['success'] == true) {
      await _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Web Page Generator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProjects),
        ],
      ),
      body:
          _isGenerating
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating your web page...'),
                    SizedBox(height: 8),
                    Text(
                      'This may take 30-60 seconds',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Generate Web Pages with AI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create complete, production-ready web pages instantly',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Templates
                    const Text(
                      'Quick Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTemplateCard(
                      'Registration Page',
                      'Complete user registration form with validation',
                      Icons.person_add,
                      Colors.blue,
                      () => _generatePage(
                        'registration',
                        WebPageGeneratorService.getRegistrationTemplate(),
                      ),
                    ),

                    _buildTemplateCard(
                      'Login Page',
                      'Secure login form with remember me option',
                      Icons.login,
                      Colors.green,
                      () => _generatePage(
                        'login',
                        WebPageGeneratorService.getLoginTemplate(),
                      ),
                    ),

                    _buildTemplateCard(
                      'Contact Form',
                      'Professional contact form with message field',
                      Icons.contact_mail,
                      Colors.orange,
                      () => _generatePage(
                        'contact',
                        WebPageGeneratorService.getContactTemplate(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Custom Prompt Section
                    const Text(
                      'Or Describe Your Own Page',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tell AI what you want to create',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _promptController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText:
                                    'Example: Create an effective dashboard with charts, stats cards, and user activity feed',
                                border: OutlineInputBorder(),
                                labelText: 'Describe your page',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedTheme,
                                    decoration: const InputDecoration(
                                      labelText: 'Theme',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'dark',
                                        child: Text('Dark'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'light',
                                        child: Text('Light'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'glassmorphism',
                                        child: Text('Glassmorphism'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedTheme = value ?? 'dark';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _generateFromPrompt,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Generate'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Generated Projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Generated Pages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isLoadingProjects)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_projects.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No pages generated yet.\nTry creating one using the templates above!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return _buildProjectCard(project);
                        },
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTemplateCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['project_name'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${project['page_type']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePage(project['project_id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                project['web_url'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => LiveWebEditorScreen(
                                projectId: project['project_id'],
                                webUrl: project['web_url'] ?? '',
                                projectName: project['project_name'] ?? 'Page',
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Live Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(project['web_url']);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Browser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
