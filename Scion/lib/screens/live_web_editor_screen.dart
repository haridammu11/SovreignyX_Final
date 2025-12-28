import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/web_page_generator_service.dart';

class LiveWebEditorScreen extends StatefulWidget {
  final String projectId;
  final String webUrl;
  final String projectName;

  const LiveWebEditorScreen({
    super.key,
    required this.projectId,
    required this.webUrl,
    required this.projectName,
  });

  @override
  State<LiveWebEditorScreen> createState() => _LiveWebEditorScreenState();
}

class _LiveWebEditorScreenState extends State<LiveWebEditorScreen> {
  late final WebViewController _controller;
  final TextEditingController _promptController = TextEditingController();
  bool _isUpdating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Web Error: ${error.description}')),
                );
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.webUrl));
  }

  Future<void> _applyUpdates() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    // Close keyboard
    FocusScope.of(context).unfocus();

    try {
      final result = await WebPageGeneratorService.modifyPage(
        projectId: widget.projectId,
        prompt: prompt,
      );

      if (result['success'] == true) {
        if (mounted) {
          // Check if linked pages were auto-generated
          final linkedPages = result['linked_pages'];

          if (linkedPages != null &&
              linkedPages is List &&
              linkedPages.isNotEmpty) {
            // Show detailed success message with linked pages info
            _showLinkedPagesDialog(linkedPages);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Updates applied successfully! 🚀')),
            );
          }

          _promptController.clear();

          // Reload the webview to show changes
          _controller.reload();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: ${result['error']}')));
        }
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
          _isUpdating = false;
        });
      }
    }
  }

  void _showLinkedPagesDialog(List linkedPages) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green),
                SizedBox(width: 8),
                Text('Pages Auto-Generated! ✨'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your page was updated successfully, and I also created these linked pages for you:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ...linkedPages.map((page) {
                  final pageName = page['page_name'] ?? 'Unknown';
                  final webUrl = page['web_url'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pageName.toUpperCase()} Page',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                webUrl,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All pages match your current design style!',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }

  void _showAiAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full screen height if needed
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Web Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ask me to change styles, layout, or content',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'e.g., "Make the background dark blue" or "Add a contact form at the bottom"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUpdating
                            ? null
                            : () {
                              Navigator.pop(context); // Close sheet
                              _applyUpdates();
                            },
                    icon:
                        _isUpdating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send),
                    label: Text(
                      _isUpdating ? 'Applying Changes...' : 'Update Page',
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_isUpdating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'AI is transforming your page...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAiAssistant,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Edit with AI'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
