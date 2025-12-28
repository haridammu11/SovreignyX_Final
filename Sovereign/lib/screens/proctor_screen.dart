import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/config_service.dart';

class ProctorScreen extends StatefulWidget {
  const ProctorScreen({super.key});

  @override
  State<ProctorScreen> createState() => _ProctorScreenState();
}

class _ProctorScreenState extends State<ProctorScreen> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  final String _backendUrl = '${ConfigService.backendBaseUrl}/api/code'; 

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchSessions();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/list-proctor-sessions/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _sessions = data['sessions'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching proctor sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takeAction(int sessionId, String action) async {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('Action "$action" initiated for Session #$sessionId'),
         behavior: SnackBarBehavior.floating,
         backgroundColor: action == 'WARN' ? Colors.orange : Colors.red,
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROCTOR COMMAND CENTER',
          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSessions,
          ),
          _buildStatusPulse(),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _sessions.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return _buildSessionCard(session);
              },
            ),
    );
  }

  Widget _buildStatusPulse() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SYNCED',
          style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No active proctoring sessions',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for students to start...',
            style: GoogleFonts.inter(color: Colors.grey.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    bool isFlagged = session['is_flagged'] ?? false;
    String? latestFrame = session['latest_frame'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFlagged ? Colors.redAccent : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isFlagged ? Colors.red.withOpacity(0.15) : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: LiveStreamWidget(
              sessionId: session['id'],
              initialFrame: latestFrame,
              isFlagged: isFlagged,
              studentId: session['user_id'].toString(),
            ),
          ),
          
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['latest_description'] ?? 'Monitoring active',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isFlagged ? Colors.redAccent : null,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.code,
                          color: Colors.blueAccent,
                          label: 'CODE',
                          onTap: () => _viewStudentCode(
                            session['user_id'].toString(),
                            session['latest_code'] ?? '// No code recorded yet',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.history,
                          color: Colors.purpleAccent,
                          label: 'HISTORY',
                          onTap: () => _viewSnapshotHistory(session['id']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.notifications_none,
                          color: Colors.orange,
                          label: 'WARN',
                          onTap: () => _takeAction(session['id'], 'WARN'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.logout,
                          color: Colors.red,
                          label: 'EXIT',
                          onTap: () => _takeAction(session['id'], 'TERMINATE'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewSnapshotHistory(int sessionId) async {
    showDialog(
      context: context,
      builder: (context) => _SnapshotHistoryDialog(sessionId: sessionId),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16),
          Text(label, style: GoogleFonts.spaceMono(fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _viewStudentCode(String studentId, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Student Code: $studentId',
          style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14),
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              code,
              style: GoogleFonts.firaCode(
                color: Colors.greenAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _SnapshotHistoryDialog extends StatefulWidget {
  final int sessionId;
  const _SnapshotHistoryDialog({required this.sessionId});

  @override
  State<_SnapshotHistoryDialog> createState() => _SnapshotHistoryDialogState();
}

class _SnapshotHistoryDialogState extends State<_SnapshotHistoryDialog> {
  List<dynamic> _snapshots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    try {
      final url = '${ConfigService.backendBaseUrl}/api/code/get-session-snapshots/${widget.sessionId}/';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _snapshots = data['snapshots'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading snapshots: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVIDENCE TIMELINE',
                      style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Session #${widget.sessionId} (Permanent Records)',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _snapshots.isEmpty
                      ? Center(child: Text('No historical snapshots found.', style: GoogleFonts.inter(color: Colors.white38)))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _snapshots.length,
                          itemBuilder: (context, index) {
                            final snap = _snapshots[index];
                            final time = DateTime.parse(snap['timestamp']).toLocal();
                            final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
                            final image = snap['image_data'];

                            return Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: snap['is_suspicious'] ? Colors.redAccent : Colors.white12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: image != null
                                        ? Image.memory(
                                            base64Decode(image.split(',').last),
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(color: Colors.black, child: const Icon(Icons.broken_image, color: Colors.white24)),
                                          )
                                        : Container(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.spaceMono(color: snap['is_suspicious'] ? Colors.redAccent : Colors.white54, fontSize: 10),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamWidget extends StatefulWidget {

  final int sessionId;
  final String? initialFrame;
  final bool isFlagged;
  final String studentId;

  const LiveStreamWidget({
    super.key,
    required this.sessionId,
    this.initialFrame,
    required this.isFlagged,
    required this.studentId,
  });

  @override
  State<LiveStreamWidget> createState() => _LiveStreamWidgetState();
}

class _LiveStreamWidgetState extends State<LiveStreamWidget> {
  WebSocketChannel? _channel;
  dynamic _lastFrame;
  final String _wsUrl = ConfigService.backendBaseUrl.replaceFirst('http', 'ws');

  @override
  void initState() {
    super.initState();
    _lastFrame = widget.initialFrame;
    _connectWs();
  }

  void _connectWs() {
    _channel = WebSocketChannel.connect(
      Uri.parse('$_wsUrl/ws/proctor/${widget.sessionId}/'),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _channel?.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _lastFrame = snapshot.data;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            if (_lastFrame != null)
              _lastFrame is String
                  ? Image.memory(
                      base64Decode(_lastFrame.split(',').last),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Image.memory(
                      _lastFrame, 
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
            else
              Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off, color: Colors.white24, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for stream',
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),
            
            if (widget.isFlagged)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.redAccent, width: 3),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.white, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STUDENT: ${widget.studentId}',
                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
