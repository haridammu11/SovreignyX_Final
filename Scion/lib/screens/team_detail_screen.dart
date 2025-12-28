import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/team_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _teamService = TeamService();
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _teamData;
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _assignedProject;
  bool _isLoading = true;
  bool _isLeader = false;

  @override
  void initState() {
    super.initState();
    _loadTeamDetails();
  }

  Future<void> _loadTeamDetails() async {
    print('═══════════════════════════════════════════════════');
    print('🔵 [LMS_APP] Loading Team Details');
    print('═══════════════════════════════════════════════════');
    print('🏷️  Team ID: ${widget.teamId}');
    print('🏷️  Team Name: ${widget.teamName}');
    
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      print('👤 Current User ID: $userId');

      // Load team data
      print('📥 Fetching team data from study_groups...');
      final teamData = await _supabase
          .from('study_groups')
          .select('*')
          .eq('id', widget.teamId)
          .single();

      print('✅ Team data loaded:');
      print('   Name: ${teamData['name']}');
      print('   Course ID: ${teamData['course_id']}');
      print('   Leader ID: ${teamData['leader_id']}');
      print('   Assigned Project ID: ${teamData['assigned_project_id']}');
      print('   Status: ${teamData['status']}');

      // Load members
      print('📥 Fetching team members...');
      final members = await _teamService.getTeamMembers(widget.teamId);
      print('✅ Found ${members.length} members');

      // Load assigned project if exists
      Map<String, dynamic>? projectData;
      if (teamData['assigned_project_id'] != null) {
        print('🎯 Team has assigned project! ID: ${teamData['assigned_project_id']}');
        try {
          print('📥 Fetching project from course_projects...');
          projectData = await _supabase
              .from('course_projects')
              .select('id, title, description, difficulty_level, github_template_url, course_id')
              .eq('id', teamData['assigned_project_id'])
              .maybeSingle();
          
          if (projectData != null) {
            print('✅ Project data loaded:');
            print('   Title: ${projectData['title']}');
            print('   Difficulty: ${projectData['difficulty_level']}');
            print('   GitHub: ${projectData['github_template_url']}');
          } else {
            print('⚠️  Project not found in database!');
          }
        } catch (e) {
          print('❌ Error fetching project: $e');
        }
      } else {
        print('ℹ️  No project assigned to this team yet');
      }

      if (mounted) {
        setState(() {
          _teamData = teamData;
          _members = members;
          _assignedProject = projectData;
          _isLeader = teamData['leader_id'] == userId;
          _isLoading = false;
        });
        
        print('═══════════════════════════════════════════════════');
        print('🎉 Team details loaded successfully!');
        print('   Has Project: ${projectData != null}');
        print('   Is Leader: ${teamData['leader_id'] == userId}');
        print('═══════════════════════════════════════════════════');
      }
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR loading team details!');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace.toString());
      print('═══════════════════════════════════════════════════');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $username from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _teamService.removeMember(
        groupId: widget.teamId,
        userId: userId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
          _loadTeamDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove member')),
          );
        }
      }
    }
  }

  Future<void> _leaveTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _teamService.leaveTeam(widget.teamId);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left team successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to leave team')),
          );
        }
      }
    }
  }

  Future<void> _updateTeamInfo() async {
    final nameController = TextEditingController(text: _teamData?['name']);
    final descController = TextEditingController(text: _teamData?['description']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Team Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _supabase
            .from('study_groups')
            .update({
              'name': nameController.text,
              'description': descController.text,
            })
            .eq('id', widget.teamId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team updated successfully')),
          );
          _loadTeamDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating team: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLeader)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _updateTeamInfo,
              tooltip: 'Edit Team',
            ),
          if (!_isLeader)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveTeam,
              tooltip: 'Leave Team',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeamDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team Info Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _teamData?['name'] ?? 'Unknown Team',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Status: ${_teamData?['status'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text('${_members.length}/4'),
                                    backgroundColor: _members.length >= 4
                                        ? Colors.red[100]
                                        : Colors.green[100],
                                  ),
                                ],
                              ),
                              if (_teamData?['description'] != null) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  _teamData!['description'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Members Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Team Members',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isLeader && _members.length < 4)
                            TextButton.icon(
                              onPressed: () {
                                // Navigate back to team formation to invite
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Invite'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Members List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final user = member['users'];
                          final isCurrentUser = user['id'] == _supabase.auth.currentUser?.id;
                          final role = member['role'] ?? 'member';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  (user['username'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['username'] ?? 'Unknown User',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (role == 'leader')
                                    const Chip(
                                      label: Text('Leader'),
                                      backgroundColor: Colors.amber,
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                  if (_isLeader && role != 'leader' && !isCurrentUser)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => _removeMember(
                                        user['id'],
                                        user['username'] ?? 'User',
                                      ),
                                      tooltip: 'Remove member',
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Project Section
                      if (_assignedProject != null) ...[
                        const Text(
                          'Assigned Project',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Colors.white,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 32,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _assignedProject!['title'] ?? 'Untitled Project',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildDifficultyBadge(_assignedProject!['difficulty_level']),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  
                                  // Description
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _assignedProject!['description'] ?? 'No description available',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // GitHub Template
                                  if (_assignedProject!['github_template_url'] != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.code, color: Colors.grey[700]),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'GitHub Template',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _assignedProject!['github_template_url'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new),
                                            onPressed: () {
                                              // Open GitHub URL
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Opening: ${_assignedProject!['github_template_url']}'),
                                                ),
                                              );
                                            },
                                            tooltip: 'Open in browser',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Project Status
                                  if (_teamData?['repo_link'] != null || _teamData?['youtube_link'] != null) ...[
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Submission Status',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_teamData?['repo_link'] != null)
                                      _buildLinkRow(
                                        Icons.link,
                                        'Repository',
                                        _teamData!['repo_link'],
                                        Colors.purple,
                                      ),
                                    if (_teamData?['youtube_link'] != null)
                                      _buildLinkRow(
                                        Icons.play_circle_outline,
                                        'Demo Video',
                                        _teamData!['youtube_link'],
                                        Colors.red,
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else if (_teamData?['assigned_project_id'] == null && _members.length >= 2) ...[
                        // No project assigned yet
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_late_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Project Assigned Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your team will be assigned a project by AI soon!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      if (_members.length >= 2 && _members.length <= 4)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to collaboration screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Collaboration feature coming soon!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.code),
                            label: const Text('Start Collaboration'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDifficultyBadge(String? difficulty) {
    final level = difficulty?.toLowerCase() ?? 'intermediate';
    Color badgeColor;
    IconData icon;

    switch (level) {
      case 'easy':
        badgeColor = Colors.green;
        icon = Icons.star_outline;
        break;
      case 'hard':
        badgeColor = Colors.red;
        icon = Icons.star;
        break;
      case 'intermediate':
      default:
        badgeColor = Colors.orange;
        icon = Icons.star_half;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            level.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(IconData icon, String label, String url, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening: $url')),
              );
            },
            tooltip: 'Open link',
          ),
        ],
      ),
    );
  }
}
