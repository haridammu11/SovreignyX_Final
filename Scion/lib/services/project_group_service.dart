import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectGroupService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get the group a user belongs to for a specific course
  Future<Map<String, dynamic>?> getUserGroup(String courseId) async {
    final userId = _client.auth.currentUser!.id;
    
    // Find membership first
    final membership = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (membership == null) return null;

    final groupId = membership['group_id'];

    // Fetch group details
    final group = await _client
        .from('study_groups')
        .select('*, members:group_members(*, user:users(*))') // deep fetch members
        .eq('id', groupId)
        .eq('course_id', courseId)
        .maybeSingle();
    
    return group;
  }

  /// Create a new group
  Future<void> createGroup(String courseId, String name) async {
    final userId = _client.auth.currentUser!.id;

    // Transaction-like logic (create group, add leader)
    // Supabase doesn't support complex transactions via SDK easily, so we chain.
    // Ideally use RPC. 
    
    final groupResponse = await _client.from('study_groups').insert({
      'course_id': courseId,
      'name': name,
      'leader_id': userId,
      'status': 'forming'
    }).select().single();

    final groupId = groupResponse['id'];

    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'leader',
      'status': 'accepted'
    });
  }

  /// Get list of groups that are forming
  Future<List<Map<String, dynamic>>> getAvailableGroups(String courseId) async {
    final response = await _client
        .from('study_groups')
        .select('*, members:group_members(count)')
        .eq('course_id', courseId)
        .eq('status', 'forming');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Request to join a group
  Future<void> requestToJoinGroup(int groupId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
      'status': 'requested' 
    });
  }

  /// Search users to invite (excluding those already in groups?)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
      final response = await _client.from('users')
          .select('id, username, first_name, last_name, profile_picture_url')
          .ilike('username', '%$query%')
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
  }

  /// Invite a user to the group
  Future<void> inviteUser(int groupId, String userId) async {
     await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'status': 'invited'
     });
  }

  /// Accept a Join Request (Leader Action)
  Future<void> acceptRequest(int memberRecordId) async {
      await _client.from('group_members').update({'status': 'accepted'}).eq('id', memberRecordId);
  }

  /// Accept an Invitation (User Action)
  Future<void> acceptInvite(int groupId) async {
       final userId = _client.auth.currentUser!.id;
       await _client.from('group_members')
           .update({'status': 'accepted'})
           .eq('group_id', groupId)
           .eq('user_id', userId);
  }

  /// Reject/Cancel Request or Invite
  Future<void> removeMember(int memberRecordId) async {
      await _client.from('group_members').delete().eq('id', memberRecordId);
  }
  
  /// Get Pending Invitations for current user
  Future<List<Map<String, dynamic>>> getPendingInvitations(String courseId) async {
      final userId = _client.auth.currentUser!.id;
      final response = await _client.from('group_members')
          .select('*, group:study_groups(*)')
          .eq('user_id', userId)
          .eq('status', 'invited');
      
      // Filter by course if needed (requires join filtering which is complex in simple query, 
      // but 'group:study_groups' fetches group details. We can filter in memory).
      final invites = List<Map<String, dynamic>>.from(response);
      return invites.where((i) => i['group'] != null && i['group']['course_id'] == courseId).toList();
  }
  
  /// Leave a group
  Future<void> leaveGroup(int groupId) async {
      final userId = _client.auth.currentUser!.id;
      await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', userId);
  }

  /// Assign a random approved project to the group
  Future<void> assignRandomProject(int groupId, String courseId) async {
    // 1. Fetch approved projects
    final projectsResponse = await _client
        .from('course_projects')
        .select()
        .eq('course_id', courseId)
        .eq('is_approved', true);
    
    final projects = List<Map<String, dynamic>>.from(projectsResponse);

    if (projects.isEmpty) {
      throw Exception('No approved projects available for this course.');
    }

    // 2. Pick random
    final random = Random();
    final project = projects[random.nextInt(projects.length)];

    // 3. Update Group
    await _client.from('study_groups').update({
      'assigned_project_id': project['id'],
      'status': 'active'
    }).eq('id', groupId);
  }

  /// Get Project Details
  Future<Map<String, dynamic>?> getProjectDetails(int projectId) async {
    return await _client.from('course_projects').select().eq('id', projectId).maybeSingle();
  }

  /// Submit Project
  Future<void> submitProject({
    required int groupId,
    required String courseId, // Added courseId
    required String repoLink,
    required String youtubeLink,
    required String docLink,
    required String videoName, // Added to store filename
    required String docName, // Added to store filename
  }) async {
    // Insert into project_submissions table
    final submissionResponse = await _client.from('project_submissions').insert({
      'student_email': _client.auth.currentUser!.email,
      'course_id': int.tryParse(courseId) ?? 0,
      'submission_type': 'file_upload',
      'status': 'submitted',
      'git_link': repoLink,
    }).select().single();

    final submissionId = submissionResponse['id'];

    // Insert files
    if (youtubeLink.isNotEmpty) {
      await _client.from('project_files').insert({
        'submission_id': submissionId,
        'file_name': videoName,
        'file_type': 'video',
        'file_size': 0, 
        'file_format': 'mp4',
        'storage_path': youtubeLink, 
        'public_url': youtubeLink
      });
    }

    if (docLink.isNotEmpty) {
      await _client.from('project_files').insert({
        'submission_id': submissionId,
        'file_name': docName,
        'file_type': 'document',
        'file_size': 0,
        'file_format': 'pdf',
        'storage_path': docLink,
        'public_url': docLink
      });
    }
    
    // Also update study_groups for backward compatibility / group status
    await _client.from('study_groups').update({
      'repo_link': repoLink,
      'youtube_link': youtubeLink,
      'documentation_link': docLink,
      'status': 'submitted', // Update status
    }).eq('id', groupId);
  }

  /// Upload a project file to Supabase Storage
  Future<String> uploadProjectFile(String courseId, String folderName, File file, String fileName) async {
    final fileExt = fileName.split('.').last;
    final path = '$courseId/$folderName/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client.storage.from('project_submissions').upload(
      path,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    final url = _client.storage.from('project_submissions').getPublicUrl(path);
    return url;
  }
}
