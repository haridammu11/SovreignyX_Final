import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/project_group_service.dart';

class GroupProjectScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const GroupProjectScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<GroupProjectScreen> createState() => _GroupProjectScreenState();
}

class _GroupProjectScreenState extends State<GroupProjectScreen> {
  final ProjectGroupService _service = ProjectGroupService();
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic>? _userGroup;
  List<Map<String, dynamic>> _availableGroups = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  Map<String, dynamic>? _assignedProject;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final group = await _service.getUserGroup(widget.courseId);
      if (group != null) {
        _userGroup = group;
        if (group['assigned_project_id'] != null) {
          _assignedProject =
              await _service.getProjectDetails(group['assigned_project_id']);
        }
      } else {
        _userGroup = null;
        _availableGroups = await _service.getAvailableGroups(widget.courseId);
        _pendingInvites = await _service.getPendingInvitations(widget.courseId);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading group data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroup() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Name Your Group'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g., The Avengers',
              prefixIcon: Icon(Icons.group_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await _service.createGroup(widget.courseId, nameController.text.trim());
      _loadData();
    }
  }

  Future<void> _requestToJoin(int groupId) async {
    try {
      await _service.requestToJoinGroup(groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.send_rounded, color: Colors.blue.shade300),
                const SizedBox(width: 12),
                const Text('Request sent!'),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _acceptInvite(int groupId) async {
    await _service.acceptInvite(groupId);
    _loadData();
  }

  Future<void> _showInviteDialog(int groupId) async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];

    await showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Invite Member'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Username',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () async {
                            final results = await _service.searchUsers(
                              searchController.text,
                            );
                            setState(() => searchResults = results);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (searchResults.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final u = searchResults[index];
                            return Card(
                              elevation: 0,
                              color: cs.surfaceContainerHighest,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      u['profile_picture_url'] != null
                                          ? NetworkImage(
                                            u['profile_picture_url'],
                                          )
                                          : null,
                                  backgroundColor: cs.primaryContainer,
                                  foregroundColor: cs.onPrimaryContainer,
                                  child:
                                      u['profile_picture_url'] == null
                                          ? Text(
                                            (u['first_name']?[0] ?? 'U')
                                                .toUpperCase(),
                                          )
                                          : null,
                                ),
                                title: Text(u['username'] ?? 'Unknown'),
                                trailing: FilledButton.icon(
                                  onPressed: () async {
                                    await _service.inviteUser(groupId, u['id']);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Invited ${u['username']}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.person_add_rounded),
                                  label: const Text('Invite'),
                                ),
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
            );
          },
        );
      },
    );
  }

  Future<void> _assignProject() async {
    try {
      setState(() => _isLoading = true);
      await _service.assignRandomProject(_userGroup!['id'], widget.courseId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning project: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProject() async {
    final repoController = TextEditingController();
    final docController = TextEditingController(); // acts as fallback or link
    
    File? _selectedVideo;
    File? _selectedDoc;
    String? _videoName;
    String? _docName;
    bool _isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Submit Project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: repoController,
                      decoration: const InputDecoration(
                        labelText: 'GitHub Repo Link',
                        prefixIcon: Icon(Icons.code_rounded),
                        hintText: 'https://github.com/username/repo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Video Selection
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.video,
                            allowMultiple: false,
                          );
                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              _selectedVideo = File(result.files.single.path!);
                              _videoName = result.files.single.name;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking video: $e');
                        }
                      },
                      icon: Icon(_selectedVideo != null ? Icons.check_circle : Icons.video_library),
                      label: Text(_videoName ?? 'Select Project Video (MP4)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedVideo != null ? Colors.green : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Document Selection
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : () async {
                         try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                            allowMultiple: false,
                          );
                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              _selectedDoc = File(result.files.single.path!);
                              _docName = result.files.single.name;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error picking doc: $e');
                        }
                      },
                      icon: Icon(_selectedDoc != null ? Icons.check_circle : Icons.description),
                      label: Text(_docName ?? 'Select Documentation (PDF)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedDoc != null ? Colors.green : null,
                      ),
                    ),
                    
                    if (_isUploading) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Uploading files...', style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!_isUploading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                FilledButton(
                  onPressed: _isUploading ? null : () async {
                    if (repoController.text.trim().isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Please provide a GitHub link')),
                         );
                        return;
                    }
                    if (_selectedVideo == null) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Please upload a project video')),
                         );
                        return;
                    }

                    setState(() => _isUploading = true);

                    try {
                      String videoUrl = '';
                      String docUrl = '';

                      // Upload Video
                      if (_selectedVideo != null) {
                        videoUrl = await _service.uploadProjectFile(
                          widget.courseId, 
                          'videos', 
                          _selectedVideo!, 
                          _videoName ?? 'video.mp4'
                        );
                      }

                      // Upload Doc
                      if (_selectedDoc != null) {
                         docUrl = await _service.uploadProjectFile(
                          widget.courseId, 
                          'docs', 
                          _selectedDoc!, 
                          _docName ?? 'doc.pdf'
                        );
                      }

                      await _service.submitProject(
                        groupId: _userGroup!['id'],
                        courseId: widget.courseId, // Accessing from widget
                        repoLink: repoController.text.trim(),
                        youtubeLink: videoUrl,
                        docLink: docUrl,
                        videoName: _videoName ?? 'project_video.mp4',
                        docName: _docName ?? 'documentation.pdf',
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Project Submitted Successfully!'),
                             backgroundColor: Colors.green,
                           ),
                        );
                        _loadData(); // Refresh UI
                      }

                    } catch (e) {
                      if (mounted) {
                         setState(() => _isUploading = false);
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Submission failed: $e')),
                         );
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
// Old actions array end was at 327

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onPrimary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body:
          _userGroup == null
              ? _buildGroupSelection()
              : _buildGroupDashboard(),
    );
  }

  Widget _buildGroupSelection() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        // Pending Invites
        if (_pendingInvites.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Invitations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final invite = _pendingInvites[index];
                final g = invite['group'];
                return Card(
                  elevation: 0,
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade200,
                      foregroundColor: Colors.orange.shade900,
                      child: const Icon(Icons.mail_rounded),
                    ),
                    title: Text(
                      'Invited to: ${g['name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () => _acceptInvite(g['id']),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await _service.removeMember(invite['id']);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _pendingInvites.length,
            ),
          ),
        ],

        // Create Group Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: _createGroup,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Group'),
            ),
          ),
        ),

        // Available Groups
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Available Groups',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        _availableGroups.isEmpty
            ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No groups looking for members.'),
                    ),
                  ),
                ),
              ),
            )
            : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final g = _availableGroups[index];
                  final memberCount = g['members']?[0]['count'] ?? 0;
                  return Card(
                    elevation: 0,
                    color: cs.surfaceContainerHighest,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: const Icon(Icons.group_rounded),
                      ),
                      title: Text(
                        g['name'] ?? 'Unnamed Group',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('$memberCount / 4 Members'),
                      trailing: FilledButton(
                        onPressed:
                            memberCount < 4
                                ? () => _requestToJoin(g['id'])
                                : null,
                        child: const Text('Request'),
                      ),
                    ),
                  );
                },
                childCount: _availableGroups.length,
              ),
            ),
      ],
    );
  }

  Widget _buildGroupDashboard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final allMembers = (_userGroup!['members'] as List?) ?? [];
    final activeMembers =
        allMembers.where((m) => m['status'] == 'accepted').toList();
    final requestedMembers =
        allMembers.where((m) => m['status'] == 'requested').toList();
    final invitedMembers =
        allMembers.where((m) => m['status'] == 'invited').toList();

    final currentUser = _client.auth.currentUser!.id;
    final isLeader = _userGroup!['leader_id'] == currentUser;
    final status = _userGroup!['status'] ?? 'forming';

    return CustomScrollView(
      slivers: [
        // Group Header Card
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        child: const Icon(Icons.group_rounded, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userGroup!['name'] ?? 'Unnamed Group',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${status.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${activeMembers.length}/4',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        backgroundColor: cs.tertiaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Join Requests (Leader Only)
        if (isLeader && requestedMembers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Join Requests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final m = requestedMembers[index];
                return Card(
                  elevation: 0,
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade200,
                      foregroundColor: Colors.orange.shade900,
                      child: Text(
                        (m['user']['first_name']?[0] ?? '?').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    title: Text(
                      '${m['user']['first_name']} ${m['user']['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Requesting to join'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            if (activeMembers.length >= 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Group full!'),
                                ),
                              );
                              return;
                            }
                            await _service.acceptRequest(m['id']);
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await _service.removeMember(m['id']);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: requestedMembers.length,
            ),
          ),
        ],

        // Members Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (isLeader && activeMembers.length < 4)
                  FilledButton.tonalIcon(
                    onPressed: () => _showInviteDialog(_userGroup!['id']),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Invite'),
                  ),
              ],
            ),
          ),
        ),

        // Active Members
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final m = activeMembers[index];
              return Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: Text(
                      (m['user']['first_name']?[0] ?? 'U').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: Text(
                    '${m['user']['first_name']} ${m['user']['last_name']}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(m['role'] ?? 'Member'),
                  trailing:
                      m['user']['id'] == _userGroup!['leader_id']
                          ? Chip(
                            label: const Text('Leader'),
                            backgroundColor: cs.tertiaryContainer,
                          )
                          : null,
                ),
              );
            },
            childCount: activeMembers.length,
          ),
        ),

        // Invited Members
        if (invitedMembers.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final m = invitedMembers[index];
                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_empty_rounded),
                    title: Text(
                      '${m['user']['first_name']} (Invited)',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: const Text('Pending Acceptance'),
                  ),
                );
              },
              childCount: invitedMembers.length,
            ),
          ),

        // Project Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status == 'forming') ...[
                  if (activeMembers.length < 3)
                    Card(
                      elevation: 0,
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Group needs at least 3 members to start project.',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (isLeader)
                    FilledButton.icon(
                      onPressed:
                          (activeMembers.length >= 3 &&
                                  activeMembers.length <= 4)
                              ? _assignProject
                              : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Start Project (Get Assignment)'),
                    ),
                ],
                if (status == 'active' || status == 'completed') ...[
                  if (_assignedProject != null) ...[
                    Card(
                      elevation: 0,
                      color: cs.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment_rounded,
                                  color: cs.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _assignedProject!['title'] ?? 'Project',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _assignedProject!['description'] ?? '',
                              style: TextStyle(color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Base Repository:',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final url =
                                    _assignedProject!['github_template_url'];
                                if (url != null) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.code_rounded,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _assignedProject![
                                              'github_template_url',
                                            ] ??
                                            'No link',
                                        style: TextStyle(
                                          color: cs.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      color: cs.primary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (status == 'active')
                      FilledButton.icon(
                        onPressed: _submitProject,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Submit Project'),
                      ),
                    if (status == 'completed')
                      Card(
                        elevation: 0,
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade700,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Project Submitted! Pending Review.',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
