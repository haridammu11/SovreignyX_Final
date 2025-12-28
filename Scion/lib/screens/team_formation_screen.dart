import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'team_detail_screen.dart';

class TeamFormationScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TeamFormationScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TeamFormationScreen> createState() => _TeamFormationScreenState();
}

class _TeamFormationScreenState extends State<TeamFormationScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _myTeams = [];
  List<Map<String, dynamic>> _availableTeams = [];
  List<Map<String, dynamic>> _pendingInvitations = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load ALL teams for this course
      final allTeamsData = await _supabase
          .from('study_groups')
          .select('id, course_id, name, description, leader_id, status')
          .eq('course_id', widget.courseId);

      // Load ALL group members for these teams
      final teamIds = (allTeamsData as List).map((t) => t['id'] as int).toList();
      
      final allMembersData = teamIds.isEmpty ? [] : await _supabase
          .from('group_members')
          .select('id, group_id, user_id, status, role')
          .inFilter('group_id', teamIds);

      // Build a map of team_id -> members
      final teamMembersMap = <int, List<Map<String, dynamic>>>{};
      for (final member in allMembersData as List) {
        final groupId = member['group_id'] as int;
        if (!teamMembersMap.containsKey(groupId)) {
          teamMembersMap[groupId] = [];
        }
        teamMembersMap[groupId]!.add(member as Map<String, dynamic>);
      }

      // Attach members to teams
      final teamsWithMembers = <Map<String, dynamic>>[];
      for (final team in allTeamsData) {
        final teamId = team['id'] as int;
        final members = teamMembersMap[teamId] ?? [];
        teamsWithMembers.add({
          ...team as Map<String, dynamic>,
          'group_members': members,
        });
      }

      // Filter MY teams (where I'm an accepted member)
      final myTeams = teamsWithMembers.where((team) {
        final members = team['group_members'] as List;
        return members.any((m) => 
          m['user_id'] == userId && m['status'] == 'accepted'
        );
      }).toList();

      // Filter AVAILABLE teams (not full, not a member, not completed)
      final availableTeams = teamsWithMembers.where((team) {
        if (team['status'] == 'completed') return false;
        
        final members = team['group_members'] as List;
        final acceptedMembers = members.where((m) => m['status'] == 'accepted').toList();
        final isMember = members.any((m) => m['user_id'] == userId);
        
        return acceptedMembers.length < 4 && !isMember;
      }).toList();

      // Load pending invitations (where I'm invited)
      final invitationsData = await _supabase
          .from('group_members')
          .select('id, group_id, user_id, status, role')
          .eq('user_id', userId)
          .eq('status', 'invited');

      // Fetch team details for invitations
      final invitationGroupIds = (invitationsData as List)
          .map((inv) => inv['group_id'] as int)
          .toList();

      final invitationTeams = invitationGroupIds.isEmpty ? [] : await _supabase
          .from('study_groups')
          .select('id, name, description, course_id')
          .inFilter('id', invitationGroupIds)
          .eq('course_id', widget.courseId);

      // Build invitations with team data
      final invitationsWithTeams = <Map<String, dynamic>>[];
      for (final inv in invitationsData) {
        final teamData = (invitationTeams as List).firstWhere(
          (t) => t['id'] == inv['group_id'],
          orElse: () => null,
        );
        if (teamData != null) {
          invitationsWithTeams.add({
            'id': inv['id'],
            'group_id': inv['group_id'],
            'user_id': inv['user_id'],
            'status': inv['status'],
            'role': inv['role'],
            'study_groups': teamData,
          });
        }
      }

      // Load pending requests (where I'm the leader and someone requested)
      final requestsData = await _supabase
          .from('group_members')
          .select('id, group_id, user_id, status, role')
          .eq('status', 'pending');

      // Fetch study_groups for this course where user is leader
      final myLeaderGroups = await _supabase
          .from('study_groups')
          .select('id, name, leader_id, course_id')
          .eq('course_id', widget.courseId)
          .eq('leader_id', userId);

      // Get IDs of groups I lead
      final myGroupIds = (myLeaderGroups as List)
          .map((g) => g['id'] as int)
          .toList();

      // Filter requests for my groups and fetch user details
      final filteredRequests = <Map<String, dynamic>>[];
      for (final request in requestsData as List) {
        if (myGroupIds.contains(request['group_id'])) {
          // Fetch user details
          final userData = await _supabase
              .from('users')
              .select('id, username, first_name, last_name')
              .eq('id', request['user_id'])
              .maybeSingle();

          // Fetch group details
          final groupData = (myLeaderGroups as List).firstWhere(
            (g) => g['id'] == request['group_id'],
            orElse: () => {'id': request['group_id'], 'name': 'Unknown'},
          );

          if (userData != null) {
            filteredRequests.add({
              'id': request['id'],
              'group_id': request['group_id'],
              'user_id': request['user_id'],
              'status': request['status'],
              'role': request['role'],
              'users': userData,
              'study_groups': groupData,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _myTeams = myTeams;
          _availableTeams = availableTeams;
          _pendingInvitations = invitationsWithTeams;
          _pendingRequests = filteredRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _createTeam() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Team'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        final userId = _supabase.auth.currentUser?.id;
        
        // Create group
        final groupData = await _supabase
            .from('study_groups')
            .insert({
              'course_id': widget.courseId,
              'name': nameController.text,
              'description': descController.text,
              'leader_id': userId,
              'status': 'forming',
            })
            .select()
            .single();

        // Add creator as member
        await _supabase.from('group_members').insert({
          'group_id': groupData['id'],
          'user_id': userId,
          'role': 'leader',
          'status': 'accepted',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team created successfully!')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating team: $e')),
          );
        }
      }
    }
  }

  Future<void> _inviteMember(int groupId) async {
    // Show user search dialog
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite Member'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by username',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        try {
                          final results = await _supabase
                              .from('users')
                              .select('id, username, first_name, last_name')
                              .ilike('username', '%${searchController.text}%')
                              .limit(10);
                          
                          setDialogState(() {
                            searchResults = List<Map<String, dynamic>>.from(results);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Search error: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          title: Text(user['username'] ?? 'Unknown'),
                          subtitle: Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _supabase.from('group_members').insert({
                                  'group_id': groupId,
                                  'user_id': user['id'],
                                  'status': 'invited',
                                  'role': 'member',
                                });
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invitation sent!')),
                                  );
                                  _loadData();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            child: const Text('Invite'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestToJoin(int groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'status': 'pending',
        'role': 'member',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _acceptInvitation(int groupMemberId) async {
    try {
      await _supabase
          .from('group_members')
          .update({'status': 'accepted'})
          .eq('id', groupMemberId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectInvitation(int groupMemberId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('id', groupMemberId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation rejected')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(int groupMemberId) async {
    try {
      await _supabase
          .from('group_members')
          .update({'status': 'accepted'})
          .eq('id', groupMemberId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(int groupMemberId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('id', groupMemberId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teams - ${widget.courseName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.group),
              text: 'My Teams',
            ),
            Tab(
              icon: const Icon(Icons.search),
              text: 'Find Teams',
            ),
            Tab(
              icon: Badge(
                label: Text('${_pendingInvitations.length}'),
                isLabelVisible: _pendingInvitations.isNotEmpty,
                child: const Icon(Icons.mail),
              ),
              text: 'Invitations',
            ),
            Tab(
              icon: Badge(
                label: Text('${_pendingRequests.length}'),
                isLabelVisible: _pendingRequests.isNotEmpty,
                child: const Icon(Icons.person_add),
              ),
              text: 'Requests',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyTeamsTab(),
                _buildAvailableTeamsTab(),
                _buildInvitationsTab(),
                _buildRequestsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTeam,
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
      ),
    );
  }

  Widget _buildMyTeamsTab() {
    if (_myTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No teams yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text('Create a team or join an existing one'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTeams.length,
        itemBuilder: (context, index) {
          final team = _myTeams[index];
          return _buildTeamCard(team, isMyTeam: true);
        },
      ),
    );
  }

  Widget _buildAvailableTeamsTab() {
    if (_availableTeams.isEmpty) {
      return const Center(
        child: Text('No available teams found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableTeams.length,
        itemBuilder: (context, index) {
          final team = _availableTeams[index];
          return _buildTeamCard(team, isMyTeam: false);
        },
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team, {required bool isMyTeam}) {
    final members = (team['group_members'] as List? ?? [])
        .where((m) => m['status'] == 'accepted')
        .toList();
    final memberCount = members.length;
    final isFull = memberCount >= 4;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    team['name'] ?? 'Unnamed Team',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text('$memberCount/4'),
                  backgroundColor: isFull ? Colors.red[100] : Colors.green[100],
                ),
              ],
            ),
            if (team['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                team['description'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(
                4,
                (index) => CircleAvatar(
                  radius: 16,
                  backgroundColor: index < memberCount
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                  child: index < memberCount
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isMyTeam)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isFull ? null : () => _inviteMember(team['id']),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Invite'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailScreen(
                              teamId: team['id'],
                              teamName: team['name'] ?? 'Team',
                            ),
                          ),
                        ).then((_) => _loadData()); // Refresh when returning
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isFull ? null : () => _requestToJoin(team['id']),
                  icon: const Icon(Icons.login),
                  label: Text(isFull ? 'Team Full' : 'Request to Join'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsTab() {
    if (_pendingInvitations.isEmpty) {
      return const Center(
        child: Text('No pending invitations'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _pendingInvitations[index];
        final group = invitation['study_groups'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.mail),
            ),
            title: Text(group['name'] ?? 'Unnamed Team'),
            subtitle: const Text('You have been invited to join this team'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptInvitation(invitation['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectInvitation(invitation['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Text('No pending requests'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final user = request['users'];
        final group = request['study_groups'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(user['username'] ?? 'Unknown User'),
            subtitle: Text('Wants to join ${group['name']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptRequest(request['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectRequest(request['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
