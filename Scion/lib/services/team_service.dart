import 'package:supabase_flutter/supabase_flutter.dart';

class TeamService {
  final _supabase = Supabase.instance.client;

  /// Get all teams for a specific course
  Future<List<Map<String, dynamic>>> getTeamsForCourse(String courseId) async {
    try {
      final response = await _supabase
          .from('study_groups')
          .select('*, group_members(user_id, status, role)')
          .eq('course_id', courseId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching teams: $e');
      return [];
    }
  }

  /// Get teams where current user is a member
  Future<List<Map<String, dynamic>>> getMyTeams(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('study_groups')
          .select('*, group_members!inner(user_id, status, role)')
          .eq('course_id', courseId)
          .eq('group_members.user_id', userId)
          .eq('group_members.status', 'accepted');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching my teams: $e');
      return [];
    }
  }

  /// Get available teams (not full, user not a member)
  Future<List<Map<String, dynamic>>> getAvailableTeams(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('team_stats')
          .select('*, study_groups!inner(*)')
          .eq('course_id', courseId)
          .gt('available_slots', 0);

      // Filter out teams where user is already a member or has pending request
      final teams = List<Map<String, dynamic>>.from(response);
      final filteredTeams = <Map<String, dynamic>>[];

      for (final team in teams) {
        final memberCheck = await _supabase
            .from('group_members')
            .select('id')
            .eq('group_id', team['group_id'])
            .eq('user_id', userId)
            .maybeSingle();

        if (memberCheck == null) {
          filteredTeams.add(team);
        }
      }

      return filteredTeams;
    } catch (e) {
      print('Error fetching available teams: $e');
      return [];
    }
  }

  /// Get pending invitations for current user
  Future<List<Map<String, dynamic>>> getPendingInvitations(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('group_members')
          .select('*, study_groups!inner(id, name, description, course_id)')
          .eq('user_id', userId)
          .eq('status', 'invited')
          .eq('study_groups.course_id', courseId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching invitations: $e');
      return [];
    }
  }

  /// Get pending join requests for teams I lead
  Future<List<Map<String, dynamic>>> getPendingRequests(String courseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('group_members')
          .select('''
            *,
            study_groups!inner(id, name, leader_id, course_id),
            users!inner(id, username, first_name, last_name)
          ''')
          .eq('status', 'pending')
          .eq('study_groups.leader_id', userId)
          .eq('study_groups.course_id', courseId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching requests: $e');
      return [];
    }
  }

  /// Create a new team
  Future<Map<String, dynamic>?> createTeam({
    required String courseId,
    required String name,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Create the team
      final teamData = await _supabase
          .from('study_groups')
          .insert({
            'course_id': courseId,
            'name': name,
            'description': description,
            'leader_id': userId,
            'status': 'forming',
          })
          .select()
          .single();

      // Add creator as leader member
      await _supabase.from('group_members').insert({
        'group_id': teamData['id'],
        'user_id': userId,
        'role': 'leader',
        'status': 'accepted',
      });

      return teamData;
    } catch (e) {
      print('Error creating team: $e');
      return null;
    }
  }

  /// Invite a user to join a team
  Future<bool> inviteMember({
    required int groupId,
    required String userId,
  }) async {
    try {
      // Check if team is full
      final memberCount = await _getAcceptedMemberCount(groupId);
      if (memberCount >= 4) {
        throw Exception('Team is full');
      }

      // Check if user already has a relationship with this team
      final existing = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('User already has a relationship with this team');
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'status': 'invited',
        'role': 'member',
      });

      return true;
    } catch (e) {
      print('Error inviting member: $e');
      return false;
    }
  }

  /// Request to join a team
  Future<bool> requestToJoin(int groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if team is full
      final memberCount = await _getAcceptedMemberCount(groupId);
      if (memberCount >= 4) {
        throw Exception('Team is full');
      }

      // Check if user already has a relationship with this team
      final existing = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You already have a relationship with this team');
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'status': 'pending',
        'role': 'member',
      });

      return true;
    } catch (e) {
      print('Error requesting to join: $e');
      return false;
    }
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(int membershipId) async {
    try {
      await _supabase
          .from('group_members')
          .update({'status': 'accepted'})
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error accepting invitation: $e');
      return false;
    }
  }

  /// Reject an invitation
  Future<bool> rejectInvitation(int membershipId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error rejecting invitation: $e');
      return false;
    }
  }

  /// Accept a join request
  Future<bool> acceptRequest(int membershipId) async {
    try {
      await _supabase
          .from('group_members')
          .update({'status': 'accepted'})
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error accepting request: $e');
      return false;
    }
  }

  /// Reject a join request
  Future<bool> rejectRequest(int membershipId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error rejecting request: $e');
      return false;
    }
  }

  /// Remove a member from team (leader only)
  Future<bool> removeMember({
    required int groupId,
    required String userId,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Verify current user is the leader
      final team = await _supabase
          .from('study_groups')
          .select('leader_id')
          .eq('id', groupId)
          .single();

      if (team['leader_id'] != currentUserId) {
        throw Exception('Only team leader can remove members');
      }

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(int groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user is the leader
      final team = await _supabase
          .from('study_groups')
          .select('leader_id')
          .eq('id', groupId)
          .single();

      if (team['leader_id'] == userId) {
        throw Exception('Team leader cannot leave. Transfer leadership or delete the team.');
      }

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error leaving team: $e');
      return false;
    }
  }

  /// Get team members
  Future<List<Map<String, dynamic>>> getTeamMembers(int groupId) async {
    try {
      // Fetch group members
      final membersData = await _supabase
          .from('group_members')
          .select('id, group_id, user_id, status, role')
          .eq('group_id', groupId)
          .eq('status', 'accepted');

      // Fetch user details for each member
      final membersWithUsers = <Map<String, dynamic>>[];
      for (final member in membersData as List) {
        final userData = await _supabase
            .from('users')
            .select('id, username, first_name, last_name')
            .eq('id', member['user_id'])
            .maybeSingle();

        if (userData != null) {
          membersWithUsers.add({
            'id': member['id'],
            'group_id': member['group_id'],
            'user_id': member['user_id'],
            'status': member['status'],
            'role': member['role'],
            'users': userData,
          });
        }
      }

      return membersWithUsers;
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('team_notifications')
          .select('*, study_groups(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await _supabase
          .from('team_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Helper: Get accepted member count
  Future<int> _getAcceptedMemberCount(int groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('status', 'accepted');

      return (response as List).length;
    } catch (e) {
      print('Error getting member count: $e');
      return 0;
    }
  }
}
