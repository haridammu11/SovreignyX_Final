import 'package:flutter/material.dart';
import 'dart:io';
import '../models/user.dart' as app_user;
import '../models/social.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';

class FollowRequestsScreen extends StatefulWidget {
  final AuthService authService;

  const FollowRequestsScreen({super.key, required this.authService});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  List<Connection> _followRequests = [];
  List<app_user.User> _requesters = [];
  bool _isLoading = true;
  late SocialService _socialService;

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.authService.token);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFollowRequests();
  }

  Future<void> _loadFollowRequests() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = widget.authService.currentUser!.id;
      final requests = await _socialService.getPendingFollowRequests(
        currentUserId,
      );

      final requesters = <app_user.User>[];

      for (var req in requests) {
        try {
          final response = await widget.authService.getUserProfileById(
            req.requesterId,
          );
          if (response['success'] == true) {
            requesters.add(app_user.User.fromJson(response['data']));
          } else {
            requesters.add(_createUnknownUser(req.requesterId));
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching requester ${req.requesterId}: $e');
          requesters.add(_createUnknownUser(req.requesterId));
        }
      }

      if (!mounted) return;
      setState(() {
        _followRequests = requests;
        _requesters = requesters;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading follow requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  app_user.User _createUnknownUser(String id) {
    return app_user.User(
      id: id,
      username: 'unknown',
      firstName: 'Unknown',
      lastName: 'User',
      email: '',
      isVerified: false,
      points: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _socialService.acceptFollowRequest(int.parse(requestId));

      setState(() {
        final index = _followRequests.indexWhere(
          (req) => req.id.toString() == requestId,
        );
        if (index != -1) {
          _followRequests.removeAt(index);
          if (index < _requesters.length) _requesters.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade300),
                const SizedBox(width: 12),
                const Text('Follow request accepted'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error accepting request: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _socialService.rejectFollowRequest(int.parse(requestId));

      setState(() {
        final index = _followRequests.indexWhere(
          (req) => req.id.toString() == requestId,
        );
        if (index != -1) {
          _followRequests.removeAt(index);
          if (index < _requesters.length) _requesters.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.block_rounded, color: Colors.orange.shade300),
                const SizedBox(width: 12),
                const Text('Follow request rejected'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error rejecting request: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildRequestItem(Connection request, app_user.User requester) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: Text(
                (requester.firstName?.isNotEmpty == true
                        ? requester.firstName![0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${requester.firstName} ${requester.lastName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${requester.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _acceptRequest(request.id.toString()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _rejectRequest(request.id.toString()),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Follow Requests',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            if (!_isLoading && _followRequests.isNotEmpty)
              Text(
                '${_followRequests.length} pending',
                style: const TextStyle(fontSize: 12),
              ),
          ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFollowRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _followRequests.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 80,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Follow Requests',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'re all caught up!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadFollowRequests,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _followRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestItem(
                      _followRequests[index],
                      _requesters[index],
                    );
                  },
                ),
              ),
    );
  }
}
