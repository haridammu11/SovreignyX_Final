import 'package:flutter/material.dart';
import '../services/social_service.dart';

/// Debug utility to test follow request functionality
/// Add this to your dashboard or create a debug screen
class FollowRequestDebugger {
  static final SocialService _socialService = SocialService();

  /// Test creating a follow request
  static Future<void> testCreateFollowRequest(
    BuildContext context, {
    required String requesterId,
    required String targetUserId,
  }) async {
    try {
      final result = await _socialService.createFollowRequest(
        requesterId: requesterId,
        targetUserId: targetUserId,
      );

      _showDebugDialog(
        context,
        'Follow Request Created ✅',
        'ID: ${result.id}\n'
            'Status: ${result.status}\n'
            'From: ${result.requesterId}\n'
            'To: ${result.targetUserId}',
      );
    } catch (e) {
      _showDebugDialog(context, 'ERROR ❌', e.toString());
    }
  }

  /// Test fetching pending requests
  static Future<void> testGetPendingRequests(
    BuildContext context, {
    required String userId,
  }) async {
    try {
      print('\n🔍 TEST: Fetching pending requests for $userId');

      final requests = await _socialService.getPendingFollowRequests(userId);

      String message = 'Found ${requests.length} pending requests\n\n';
      for (int i = 0; i < requests.length; i++) {
        message +=
            'Request ${i + 1}:\n'
            '  ID: ${requests[i].id}\n'
            '  From: ${requests[i].requesterId}\n'
            '  Status: ${requests[i].status}\n\n';
      }

      _showDebugDialog(context, 'Pending Requests ✅', message);
    } catch (e) {
      _showDebugDialog(context, 'ERROR ❌', e.toString());
    }
  }

  /// Test getting pending count
  static Future<void> testGetPendingCount(
    BuildContext context, {
    required String userId,
  }) async {
    try {
      print('\n🔍 TEST: Getting pending count for $userId');

      final count = await _socialService.getPendingFollowRequestsCount(userId);

      _showDebugDialog(
        context,
        'Pending Request Count ✅',
        'User: $userId\nPending Requests: $count',
      );
    } catch (e) {
      _showDebugDialog(context, 'ERROR ❌', e.toString());
    }
  }

  /// Test accepting a request
  static Future<void> testAcceptRequest(
    BuildContext context, {
    required int requestId,
  }) async {
    try {
      print('\n🔍 TEST: Accepting request ID: $requestId');

      await _socialService.acceptFollowRequest(requestId);

      _showDebugDialog(
        context,
        'Request Accepted ✅',
        'Request ID: $requestId\nStatus: Now ACCEPTED',
      );
    } catch (e) {
      _showDebugDialog(context, 'ERROR ❌', e.toString());
    }
  }

  /// Test rejecting a request
  static Future<void> testRejectRequest(
    BuildContext context, {
    required int requestId,
  }) async {
    try {
      print('\n🔍 TEST: Rejecting request ID: $requestId');

      await _socialService.rejectFollowRequest(requestId);

      _showDebugDialog(
        context,
        'Request Rejected ✅',
        'Request ID: $requestId\nStatus: Now REJECTED',
      );
    } catch (e) {
      _showDebugDialog(context, 'ERROR ❌', e.toString());
    }
  }

  /// Helper to show debug dialog
  static void _showDebugDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: SelectableText(message)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Build a debug panel widget
  static Widget buildDebugPanel({
    required String userId,
    required String targetUserId,
  }) {
    return Builder(
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Follow Request Debug Panel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () => testCreateFollowRequest(
                      context,
                      requesterId: userId,
                      targetUserId: targetUserId,
                    ),
                child: const Text('Create Follow Request'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    () => testGetPendingRequests(context, userId: userId),
                child: const Text('Get Pending Requests'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => testGetPendingCount(context, userId: userId),
                child: const Text('Get Pending Count'),
              ),
            ],
          ),
    );
  }
}

/// Example debug screen
class FollowRequestDebugScreen extends StatefulWidget {
  final String userId;
  final String targetUserId;

  const FollowRequestDebugScreen({
    required this.userId,
    required this.targetUserId,
  });

  @override
  State<FollowRequestDebugScreen> createState() =>
      _FollowRequestDebugScreenState();
}

class _FollowRequestDebugScreenState extends State<FollowRequestDebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow Request Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(widget.userId),
                    const SizedBox(height: 16),
                    const Text(
                      'Target User:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(widget.targetUserId),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FollowRequestDebugger.buildDebugPanel(
              userId: widget.userId,
              targetUserId: widget.targetUserId,
            ),
          ],
        ),
      ),
    );
  }
}
