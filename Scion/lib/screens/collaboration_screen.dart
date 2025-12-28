import 'package:flutter/material.dart';
import 'package:lms_app/services/websocket_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollaborationScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String? token;
  final int projectId;
  final String projectName;

  const CollaborationScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.token,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late WebSocketService _websocketService;
  late String _displayUserName;
  bool _isConnected = false;
  String _errorMessage = '';
  String _documentContent = '';
  List<Map<String, dynamic>> _collaborators = [];
  final TextEditingController _documentController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _websocketService = WebSocketService();
    _displayUserName = widget.userName;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initCollaboration();
  }

  Future<void> _initCollaboration() async {
    if (_displayUserName.startsWith('User ')) {
      try {
        final data =
            await Supabase.instance.client
                .from('users')
                .select('username, first_name, last_name')
                .eq('id', widget.userId)
                .maybeSingle();

        if (data != null) {
          String name =
              '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
          if (name.isEmpty) {
            name = data['username'] ?? '';
          }

          if (name.isNotEmpty) {
            if (mounted) setState(() => _displayUserName = name);
          }
        }
      } catch (e) {
        print('Error fetching user name for collaboration: $e');
      }
    }
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _documentController.dispose();
    _pulseController.dispose();
    _websocketService.disconnect();
    super.dispose();
  }

  Future<void> _connectToWebSocket() async {
    try {
      await _websocketService.connect(
        token: widget.token,
        onMessageReceived: _handleWebSocketMessage,
        onConnectionClosed: _handleWebSocketDisconnect,
      );

      _websocketService.sendMessage({
        'type': 'join_collaboration',
        'project_id': widget.projectId,
        'user_id': widget.userId,
        'username': _displayUserName,
      });

      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect to collaboration session: $e';
        });
      }
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final messageType = message['type'];

    if (messageType == 'document_update') {
      setState(() {
        _documentContent = message['content'];
        _documentController.text = _documentContent;
      });
    } else if (messageType == 'user_joined') {
      final user = {
        'id': message['user_id'],
        'name': message['username'],
        'color': _getUserColor(message['user_id']),
      };

      setState(() {
        _collaborators.add(user);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.person_add, color: Colors.white),
              const SizedBox(width: 12),
              Text('${message['username']} joined the collaboration'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (messageType == 'user_left') {
      setState(() {
        _collaborators.removeWhere((user) => user['id'] == message['user_id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.person_remove, color: Colors.white),
              const SizedBox(width: 12),
              Text('${message['username']} left the collaboration'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (messageType == 'cursor_position') {
      // Handle cursor position updates
    }
  }

  void _handleWebSocketDisconnect() {
    setState(() {
      _isConnected = false;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _connectToWebSocket();
      }
    });
  }

  Color _getUserColor(int userId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[userId % colors.length];
  }

  void _onDocumentChanged() {
    if (_websocketService.isConnected) {
      _websocketService.sendMessage({
        'type': 'document_update',
        'project_id': widget.projectId,
        'content': _documentController.text,
        'user_id': widget.userId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Collaboration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.projectName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.deepPurple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _isConnected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected ? Colors.green : Colors.red,
                        boxShadow:
                            _isConnected
                                ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(
                                      0.5 + _pulseController.value * 0.5,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                                : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Live' : 'Offline',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body:
          _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade100, Colors.orange.shade100],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _connectToWebSocket,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.03),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Collaborators bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.blue.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Collaborators (${_collaborators.length + 1})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Current user
                                  _buildCollaboratorBadge(
                                    _displayUserName,
                                    _getUserColor(widget.userId),
                                    isCurrentUser: true,
                                  ),
                                  const SizedBox(width: 8),
                                  // Other collaborators
                                  ..._collaborators.map((collaborator) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildCollaboratorBadge(
                                        collaborator['name'],
                                        collaborator['color'],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Document editor
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              width: 2,
                              color: Colors.transparent,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: TextField(
                              controller: _documentController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                              decoration: InputDecoration(
                                hintText:
                                    'Start collaborating on your project...\n\nType here and your changes will be synced in real-time with all collaborators.',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                              onChanged: (_) => _onDocumentChanged(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isConnected ? _onDocumentChanged : null,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.share,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                Icons.download,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: const Text('Export'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCollaboratorBadge(
    String name,
    Color color, {
    bool isCurrentUser = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCurrentUser ? '$name (You)' : name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
