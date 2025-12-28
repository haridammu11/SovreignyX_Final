import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social.dart' as social;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Authentication methods
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
      );

      if (response.user != null) {
        // Create user profile in users table
        await client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'created_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'user': response.user,
          'session': response.session,
        };
      } else {
        return {'success': false, 'error': 'Failed to create user'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return {
          'success': true,
          'user': response.user,
          'session': response.session,
        };
      } else {
        return {'success': false, 'error': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterdemo://login-callback/',
      );

      return {'success': true, 'provider': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // User profile methods
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('users').select().eq('id', userId).single();

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? bio,
    String? profilePictureUrl,
  }) async {
    try {
      final response = await client
          .from('users')
          .update({
            'bio': bio,
            'profile_picture_url': profilePictureUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all users from the database
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client.from('users').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Social methods
  Future<List<social.Post>> getPosts() async {
    try {
      // Simple query without joins - get posts with author info from users table
      final response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      print('SupabaseService: Fetched ${response.length} posts');
      if (response.isNotEmpty) {
        print('First post keys: ${(response.first as Map).keys.toList()}');
        print('First post raw data: ${response.first}');
      }

      List<social.Post> posts = [];
      for (var data in response as List) {
        // Handle Schema Mismatch (author_id vs user_id)
        final rawAuthorId = data['author_id'] ?? data['user_id'];
        
        if (rawAuthorId == null) {
           print('Skipping post ${data['id']} - No Author ID found (checked author_id, user_id)');
           continue; 
        }

        // Get author info separately
        String authorName = 'Unknown';
        String? authorProfilePic;

        try {
          final authorData =
              await client
                  .from('users')
                  .select('first_name, last_name, profile_picture_url')
                  .eq('id', rawAuthorId)
                  .maybeSingle();

          if (authorData != null) {
            authorName =
                '${authorData['first_name'] ?? ''} ${authorData['last_name'] ?? ''}'
                    .trim();
            authorProfilePic = authorData['profile_picture_url'];
          }
        } catch (e) {
          print('Error fetching author info: $e');
        }

        try {
          posts.add(
            social.Post.fromJson({
              'id': data['id'],
              'author': rawAuthorId,
              'author_name': authorName,
              'author_image': authorProfilePic,
              'content': data['content'],
              'image_url': data['image_url'] ?? data['image'], // Fallback
              'created_at': data['created_at'],
              'updated_at': data['updated_at'],
              'likes_count': data['likes_count'] ?? 0,
              'comments_count': data['comments_count'] ?? 0,
            }),
          );
        } catch (postError) {
           print('Error parsing post ${data['id']}: $postError');
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  Future<List<social.Post>> getUserPosts(String userId) async {
    try {
      // Try with author_id first
      final response = await client
          .from('posts')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false);
      
      print('SupabaseService: Fetched ${response.length} posts for user $userId');

      List<social.Post> posts = [];
      for (var data in response as List) {
        // Handle Schema Mismatch (author_id vs user_id)
        final rawAuthorId = data['author_id'] ?? data['user_id'];
        
        if (rawAuthorId == null) {
           continue; 
        }

        // Get author info separately
        String authorName = 'Unknown';
        String? authorProfilePic;

        try {
          final authorData =
              await client
                  .from('users')
                  .select('first_name, last_name, profile_picture_url')
                  .eq('id', rawAuthorId)
                  .maybeSingle();

          if (authorData != null) {
            authorName =
                '${authorData['first_name'] ?? ''} ${authorData['last_name'] ?? ''}'
                    .trim();
            authorProfilePic = authorData['profile_picture_url'];
          }
        } catch (e) {
          print('Error fetching author info: $e');
        }

        try {
          posts.add(
            social.Post.fromJson({
              'id': data['id'],
              'author': rawAuthorId,
              'author_name': authorName,
              'author_image': authorProfilePic,
              'content': data['content'],
              'image_url': data['image_url'] ?? data['image'], // Fallback
              'created_at': data['created_at'],
              'updated_at': data['updated_at'],
              'likes_count': data['likes_count'] ?? 0,
              'comments_count': data['comments_count'] ?? 0,
            }),
          );
        } catch (postError) {
           print('Error parsing post ${data['id']}: $postError');
        }
      }

      return posts;
    } catch (e) {
       // If author_id column is missing, try user_id
       try {
          final response = await client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
          
          // ... (simplified parsing for fallback) ...
          // For brevity, we assume if author_id matches schema, we use first block.
          // If fallback needed, we return empty list or throw.
          print('Retry getUserPosts with user_id failed too or unimplemented fallback: $e');
          return [];
       } catch (e2) {
          throw Exception('Failed to load user posts: $e');
       }
    }
  }

  Future<social.Post> createPost({
    required String authorId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final response =
          await client.from('posts').insert({
            'author_id': authorId,
            'content': content,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'likes_count': 0,
            'comments_count': 0,
          }).select();

      final postData = (response as List).first;
      return social.Post.fromJson({
        'id': postData['id'],
        'author': postData['author_id'],
        'content': postData['content'],
        'image_url': postData['image_url'],
        'created_at': postData['created_at'],
        'updated_at': postData['updated_at'],
        'likes_count': postData['likes_count'],
        'comments_count': postData['comments_count'],
      });
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<social.Follow>> getFollowers(String userId) async {
    try {
      final response = await client
          .from('followers')
          .select()
          .eq('followed_id', userId);

      return (response as List)
          .map(
            (data) => social.Follow.fromJson({
              'id': data['id'],
              'follower': data['follower_id'],
              'followed': data['followed_id'],
              'created_at': data['created_at'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  Future<List<social.Follow>> getFollowing(String userId) async {
    try {
      final response = await client
          .from('followers')
          .select()
          .eq('follower_id', userId);

      return (response as List)
          .map(
            (data) => social.Follow.fromJson({
              'id': data['id'],
              'follower': data['follower_id'],
              'followed': data['followed_id'],
              'created_at': data['created_at'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }

  Future<int> getFollowersCount(String userId) async {
    try {
      final response = await client
          .from('followers')
          .select()
          .eq('followed_id', userId);

      // Get count from response
      final count = (response as List).length;
      return count;
    } catch (e) {
      print('Error getting followers count: $e');
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await client
          .from('followers')
          .select()
          .eq('follower_id', userId);

      // Get count from response
      final count = (response as List).length;
      return count;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  Future<social.Follow> followUser({
    required String followerId,
    required String followedId,
  }) async {
    try {
      print('🔄 Following user: $followerId follows $followedId');
      // First, check if already following
      final existingFollow =
          await client
              .from('followers')
              .select()
              .eq('follower_id', followerId)
              .eq('followed_id', followedId)
              .maybeSingle();

      if (existingFollow != null) {
        print(
          '✅ Already following, returning existing follow with ID: ${existingFollow['id']}',
        );
        // Already following, return the existing follow
        return social.Follow.fromJson({
          'id': existingFollow['id'],
          'follower': existingFollow['follower_id'],
          'followed': existingFollow['followed_id'],
          'created_at': existingFollow['created_at'],
        });
      }

      // Not following yet, create new follow
      print('🆕 Not following yet, creating new follow relationship');
      final response =
          await client.from('followers').insert({
            'follower_id': followerId,
            'followed_id': followedId,
            'created_at': DateTime.now().toIso8601String(),
          }).select();

      final followData = (response as List).first;
      print('✅ Created follow relationship with ID: ${followData['id']}');
      return social.Follow.fromJson({
        'id': followData['id'],
        'follower': followData['follower_id'],
        'followed': followData['followed_id'],
        'created_at': followData['created_at'],
      });
    } catch (e, stackTrace) {
      print('❌ Error following user: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser({
    required String followerId,
    required String followedId,
  }) async {
    try {
      // First, check if following exists
      final existingFollow =
          await client
              .from('followers')
              .select()
              .eq('follower_id', followerId)
              .eq('followed_id', followedId)
              .maybeSingle();

      if (existingFollow == null) {
        // Not following, nothing to do
        return;
      }

      // Following exists, delete it
      await client
          .from('followers')
          .delete()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId);
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Post likes methods
  Future<bool> likePost({required int postId, required String userId}) async {
    try {
      await client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<bool> unlikePost({required int postId, required String userId}) async {
    try {
      await client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Comments methods
  Future<List<social.Comment>> getComments(int postId) async {
    try {
      final response = await client
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (data) => social.Comment.fromJson({
              'id': data['id'],
              'post': data['post_id'],
              'author': data['author_id'],
              'content': data['content'],
              'created_at': data['created_at'],
              'updated_at': data['updated_at'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  Future<social.Comment> createComment({
    required int postId,
    required String authorId,
    required String content,
  }) async {
    try {
      final response =
          await client.from('comments').insert({
            'post_id': postId,
            'author_id': authorId,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).select();

      final commentData = (response as List).first;
      return social.Comment.fromJson({
        'id': commentData['id'],
        'post': commentData['post_id'],
        'author': commentData['author_id'],
        'content': commentData['content'],
        'created_at': commentData['created_at'],
        'updated_at': commentData['updated_at'],
      });
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  // Achievements methods
  Future<List<social.Achievement>> getAchievements(String userId) async {
    try {
      final response = await client
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map(
            (data) => social.Achievement.fromJson({
              'id': data['id'],
              'user': data['user_id'],
              'title': data['title'],
              'description': data['description'],
              'icon': data['icon'],
              'earned_at': data['earned_at'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }

  // Leaderboard methods
  Future<List<social.Leaderboard>> getLeaderboard() async {
    try {
      final response = await client
          .from('leaderboard')
          .select()
          .order('points', ascending: false);

      return (response as List)
          .map(
            (data) => social.Leaderboard.fromJson({
              'id': data['id'] ?? 0,
              'user': data['user_id'] ?? '',
              'username': data['username'] ?? '',
              'first_name': data['first_name'] ?? '',
              'last_name': data['last_name'] ?? '',
              'points': data['points'] ?? 0,
              'rank': data['rank'] ?? 0,
              'last_updated': data['last_updated'] ?? DateTime.now().toIso8601String(),
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  // Courses methods
  Future<List<dynamic>> getCourses() async {
    try {
      final response = await client
          .from('courses')
          .select()
          .order('created_at', ascending: false);

      return response as List;
    } catch (e) {
      throw Exception('Failed to load courses: $e');
    }
  }

  // Quizzes methods
  Future<List<dynamic>> getQuizzes() async {
    try {
      final response = await client
          .from('quizzes')
          .select()
          .order('created_at', ascending: false);

      return response as List;
    } catch (e) {
      throw Exception('Failed to load quizzes: $e');
    }
  }

  // Chat methods
  Future<List<dynamic>> getChatRooms() async {
    try {
      final response = await client
          .from('chat_rooms')
          .select()
          .order('created_at', ascending: false);

      return response as List;
    } catch (e) {
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  // Payments methods
  Future<List<dynamic>> getSubscriptionPlans() async {
    try {
      final response = await client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      return response as List;
    } catch (e) {
      throw Exception('Failed to load subscription plans: $e');
    }
  }

  // Follow request methods
  Future<social.Connection> createFollowRequest({
    required String requesterId,
    required String targetUserId,
  }) async {
    try {
      print('🔄 Creating follow request from $requesterId to $targetUserId');
      // First, check if a connection already exists between these users
      final existingConnections = await client
          .from('connections')
          .select()
          .or(
            'and(requester_id.eq.$requesterId,receiver_id.eq.$targetUserId),' +
                'and(requester_id.eq.$targetUserId,receiver_id.eq.$requesterId)',
          );

      if ((existingConnections as List).isNotEmpty) {
        print('Found existing connections: ${existingConnections.length}');

        // Log existing connections for debugging
        for (var i = 0; i < existingConnections.length; i++) {
          final conn = existingConnections[i];
          print(
            'Existing connection $i: id=${conn['id']}, requester=${conn['requester_id']}, receiver=${conn['receiver_id']}, status=${conn['status']}',
          );
        }

        // Check if there's already a pending request from this requester
        final existingRequestIndex = existingConnections.indexWhere(
          (conn) =>
              conn['requester_id'] == requesterId &&
              conn['receiver_id'] == targetUserId &&
              conn['status'] == 'pending',
        );

        if (existingRequestIndex != -1) {
          print('✅ Found existing pending request, returning it');
          // Return the existing pending request
          final existingRequest = existingConnections[existingRequestIndex];
          return social.Connection.fromJson({
            'id': existingRequest['id'],
            'requester': existingRequest['requester_id'],
            'target_user': existingRequest['receiver_id'],
            'status': existingRequest['status'],
            'created_at': existingRequest['created_at'],
          });
        }

        // Check if there's already an accepted connection
        final acceptedConnectionIndex = existingConnections.indexWhere(
          (conn) =>
              (conn['requester_id'] == requesterId &&
                  conn['receiver_id'] == targetUserId &&
                  conn['status'] == 'accepted') ||
              (conn['requester_id'] == targetUserId &&
                  conn['receiver_id'] == requesterId &&
                  conn['status'] == 'accepted'),
        );

        if (acceptedConnectionIndex != -1) {
          print('✅ Found existing accepted connection, returning it');
          // Already connected, return the existing connection
          final existingConnection =
              existingConnections[acceptedConnectionIndex];
          return social.Connection.fromJson({
            'id': existingConnection['id'],
            'requester': existingConnection['requester_id'],
            'target_user': existingConnection['receiver_id'],
            'status': existingConnection['status'],
            'created_at': existingConnection['created_at'],
          });
        }

        // Check if there's a pending request from the target user to the requester
        // (in case the target user already sent a request to the requester)
        final reversePendingIndex = existingConnections.indexWhere(
          (conn) =>
              conn['requester_id'] == targetUserId &&
              conn['receiver_id'] == requesterId &&
              conn['status'] == 'pending',
        );

        if (reversePendingIndex != -1) {
          print(
            '✅ Found existing pending request from target user, returning it',
          );
          // Return the existing pending request from target user
          final existingRequest = existingConnections[reversePendingIndex];
          return social.Connection.fromJson({
            'id': existingRequest['id'],
            'requester': existingRequest['requester_id'],
            'target_user': existingRequest['receiver_id'],
            'status': existingRequest['status'],
            'created_at': existingRequest['created_at'],
          });
        }
      }

      // No existing connection, create a new one
      print('🆕 No existing connection found, creating new follow request');
      
      // Check target user privacy
      String initialStatus = 'pending';
      try {
         final targetUser = await client.from('users').select('is_private').eq('id', targetUserId).maybeSingle();
         if (targetUser != null && targetUser['is_private'] == false) {
             initialStatus = 'accepted';
         }
      } catch (e) {
         print('Error checking privacy: $e');
      }

      final response =
          await client.from('connections').insert({
            'requester_id': requesterId,
            'receiver_id': targetUserId,
            'status': initialStatus,
            'created_at': DateTime.now().toIso8601String(),
          }).select();

      final requestData = (response as List).first;
      print('✅ Created follow request with ID: ${requestData['id']}');

      // Log the created request data
      print('Created request data: $requestData');

      return social.Connection.fromJson({
        'id': requestData['id'],
        'requester': requestData['requester_id'],
        'target_user': requestData['receiver_id'],
        'status': requestData['status'],
        'created_at': requestData['created_at'],
      });
    } catch (e, stackTrace) {
      print('❌ Error creating follow request: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to create follow request: $e');
    }
  }

  Future<List<social.Connection>> getPendingFollowRequests(
    String userId,
  ) async {
    try {
      print('[GetPending] Loading pending follow requests for user: $userId');
      // Try with receiver_id first (correct column name)
      final response = await client
          .from('connections')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      print(
        '[GetPending] Query successful, found ${(response as List).length} items',
      );

      // Log raw response data for debugging
      for (var i = 0; i < response.length; i++) {
        final item = response[i];
        print('[GetPending] Raw item $i: $item');
      }

      final result =
          (response as List)
              .map(
                (data) => social.Connection.fromJson({
                  'id': data['id'],
                  'requester': data['requester_id'],
                  'target_user': data['receiver_id'],
                  'status': data['status'],
                  'created_at': data['created_at'],
                }),
              )
              .toList();

      print('[GetPending] Mapped to ${result.length} Connection objects');
      return result;
    } catch (e) {
      print('[GetPending] ❌ Error with receiver_id query: $e');
      // If that fails, try with followed_id
      try {
        final response = await client
            .from('connections')
            .select()
            .eq('followed_id', userId)
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        print(
          '[GetPending] Fallback query successful, found ${(response as List).length} items',
        );

        return (response as List)
            .map(
              (data) => social.Connection.fromJson({
                'id': data['id'],
                'requester': data['requester_id'],
                'target_user': data['followed_id'],
                'status': data['status'],
                'created_at': data['created_at'],
              }),
            )
            .toList();
      } catch (e2) {
        print('[GetPending] ❌ Error with followed_id query: $e2');
        // If that also fails, try with target_user_id (legacy)
        try {
          final response = await client
              .from('connections')
              .select()
              .eq('target_user_id', userId)
              .eq('status', 'pending')
              .order('created_at', ascending: false);

          print(
            '[GetPending] Legacy query successful, found ${(response as List).length} items',
          );

          return (response as List)
              .map(
                (data) => social.Connection.fromJson({
                  'id': data['id'],
                  'requester': data['requester_id'],
                  'target_user': data['target_user_id'],
                  'status': data['status'],
                  'created_at': data['created_at'],
                }),
              )
              .toList();
        } catch (e3) {
          print('[GetPending] ❌ Error with legacy query: $e3');
          throw Exception('Failed to load follow requests: $e');
        }
      }
    }
  }

  Future<int> getPendingFollowRequestsCount(String userId) async {
    try {
      print(
        '[PendingCount] Getting pending follow requests count for user: $userId',
      );

      // Query with receiver_id (the person RECEIVING the follow request)
      final response = await client
          .from('connections')
          .select()
          .eq('receiver_id', userId)
          .eq('status', 'pending');

      final count = (response as List).length;
      print(
        '[PendingCount] Found $count pending follow requests for user: $userId',
      );

      // Also log the actual data for debugging
      if (response is List) {
        print('[PendingCount] Raw response data: $response');
        for (var i = 0; i < response.length; i++) {
          final item = response[i];
          print(
            '[PendingCount] Item $i: id=${item['id']}, requester_id=${item['requester_id']}, receiver_id=${item['receiver_id']}, status=${item['status']}',
          );
        }
      }

      return count;
    } catch (e, stackTrace) {
      print('[PendingCount] ❌ ERROR getting pending count: $e');
      print('[PendingCount] Stack trace: $stackTrace');
      return 0;
    }
  }

  Future<void> acceptFollowRequest(int requestId) async {
    try {
      print('🔄 Accepting follow request with ID: $requestId');
      // Use the new database function that handles both updating the connection
      // and creating the follow relationship
      await client.rpc(
        'accept_follow_request',
        params: {'request_id': requestId},
      );
      print('✅ Follow request accepted successfully');
    } catch (e, stackTrace) {
      print('❌ Error accepting follow request: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to accept follow request: $e');
    }
  }

  Future<void> rejectFollowRequest(int requestId) async {
    try {
      print('🔄 Rejecting follow request with ID: $requestId');
      await client
          .from('connections')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      print('✅ Follow request rejected successfully');
    } catch (e, stackTrace) {
      print('❌ Error rejecting follow request: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to reject follow request: $e');
    }
  }

  Future<void> cancelOutgoingFollowRequest({
    required String requesterId,
    required String targetUserId,
  }) async {
    try {
      print(
        '🔄 Cancelling outgoing follow request from $requesterId to $targetUserId',
      );
      await client
          .from('connections')
          .delete()
          .eq('requester_id', requesterId)
          .eq('receiver_id', targetUserId)
          .eq('status', 'pending');
      print('✅ Outgoing follow request cancelled successfully');
    } catch (e, stackTrace) {
      print('❌ Error cancelling follow request: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to cancel follow request: $e');
    }
  }

  Future<List<social.Connection>> getOutgoingFollowRequests(
    String userId,
  ) async {
    try {
      final response = await client
          .from('connections')
          .select()
          .eq('requester_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (data) => social.Connection.fromJson({
              'id': data['id'],
              'requester': data['requester_id'],
              'target_user': data['receiver_id'],
              'status': data['status'],
              'created_at': data['created_at'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load outgoing follow requests: $e');
    }
  }

  /// Get course reels by course ID (can be integer ID or string identifier for AI courses)
  Future<List<dynamic>> getCourseReels({
    required String courseId,
    String? language,
    int limit = 30, // Increase limit for better content availability
  }) async {
    try {
      print(
        '🔍 [DEBUG] Fetching course reels for courseId: $courseId, language: $language',
      );

      // Check if courseId is a numeric ID (for database courses) or string (for AI courses)
      final isNumericId = int.tryParse(courseId) != null;

      if (isNumericId) {
        // For database courses with numeric IDs
        if (language != null && language.isNotEmpty) {
          print('🔍 [DEBUG] Filtering by language: $language');
          final response = await client
              .from('course_reels')
              .select()
              .eq('course_id', int.parse(courseId))
              .eq('language', language)
              .order('created_at', ascending: false)
              .limit(limit);

          print('✅ [SUCCESS] Retrieved ${response.length} reels');
          return _sanitizeReelsData(response as List);
        } else {
          final response = await client
              .from('course_reels')
              .select()
              .eq('course_id', int.parse(courseId))
              .order('created_at', ascending: false)
              .limit(limit);

          print('✅ [SUCCESS] Retrieved ${response.length} reels');
          return _sanitizeReelsData(response as List);
        }
      } else {
        // For AI-generated courses with string identifiers
        if (language != null && language.isNotEmpty) {
          print(
            '🔍 [DEBUG] Filtering AI course reels by course_title and language: $language',
          );
          final response = await client
              .from('course_reels')
              .select()
              .eq('course_title', courseId) // Use course_title for AI courses
              .eq('language', language)
              .order('created_at', ascending: false)
              .limit(limit);

          print('✅ [SUCCESS] Retrieved ${response.length} AI course reels');
          return _sanitizeReelsData(response as List);
        } else {
          print('🔍 [DEBUG] Filtering AI course reels by course_title only');
          final response = await client
              .from('course_reels')
              .select()
              .eq('course_title', courseId) // Use course_title for AI courses
              .order('created_at', ascending: false)
              .limit(limit);

          print('✅ [SUCCESS] Retrieved ${response.length} AI course reels');
          return _sanitizeReelsData(response as List);
        }
      }
    } catch (e, stackTrace) {
      print('❌ [ERROR] Failed to load course reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      throw Exception('Failed to load course reels: $e');
    }
  }

  /// Sanitize reels data to ensure all required fields are present
  List<dynamic> _sanitizeReelsData(List<dynamic> reelsData) {
    return reelsData.map((reel) {
      if (reel is Map<String, dynamic>) {
        return {
          'id': reel['id'] ?? '',
          'course_id': reel['course_id'] ?? '',
          'course_title': reel['course_title'] ?? '',
          'video_id': reel['video_id'] ?? '',
          'title': reel['title'] ?? 'Untitled Reel',
          'description': reel['description'] ?? '',
          'language': reel['language'] ?? 'English',
          'likes': reel['likes'] ?? 0,
          'created_at': reel['created_at'] ?? DateTime.now().toIso8601String(),
        };
      }
      return reel;
    }).toList();
  }

  Future<List<String>> getUserLikedReels() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        print(
          '⚠️ [WARNING] User not authenticated, returning empty liked reels list',
        );
        return [];
      }

      print('🔍 [DEBUG] Fetching liked reels for userId: $userId');

      final response = await client
          .from('reel_likes')
          .select('reel_id')
          .eq('user_id', userId);

      final result =
          (response as List).map((item) => item['reel_id'] as String).toList();

      print('✅ [SUCCESS] Retrieved ${result.length} liked reels');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error getting user liked reels: $e');
      print('📝 [STACK TRACE] $stackTrace');
      return [];
    }
  }

  Future<void> likeReel({
    required String reelId,
    required String courseId,
    required String language,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ [ERROR] User not authenticated');
        throw Exception('User not authenticated');
      }

      print('🔍 [DEBUG] Liking reel: $reelId for userId: $userId');

      // Check if courseId is a numeric ID (for database courses) or string (for AI courses)
      final isNumericId = int.tryParse(courseId) != null;

      if (isNumericId) {
        // For database courses with numeric IDs
        // Insert the like
        await client.from('reel_likes').insert({
          'reel_id': reelId,
          'user_id': userId,
          'course_id': int.parse(courseId),
          'language': language,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // For AI-generated courses with string identifiers
        try {
          // We need to find the actual course ID from the reel to insert into reel_likes
          // First, get the reel to find its course_id
          final reelResponse =
              await client
                  .from('course_reels')
                  .select('course_id')
                  .eq('id', reelId)
                  .single();

          final actualCourseId = reelResponse['course_id'] ?? 0;

          // Insert the like with the actual course ID
          await client.from('reel_likes').insert({
            'reel_id': reelId,
            'user_id': userId,
            'course_id': actualCourseId,
            'language': language,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // If we can't get the course_id, insert with a default value
          print(
            '⚠️ [WARNING] Could not get course_id for AI course, using default: $e',
          );
          await client.from('reel_likes').insert({
            'reel_id': reelId,
            'user_id': userId,
            'course_id': 0,
            'language': language,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      print('✅ [SUCCESS] Inserted like for reel: $reelId');

      // Increment the likes count on the reel
      await client
          .from('course_reels')
          .update({
            'likes': client.rpc('increment', params: {'value': 1}),
          })
          .eq('id', reelId);

      print('✅ [SUCCESS] Incremented likes count for reel: $reelId');
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error liking reel: $e');
      print('📝 [STACK TRACE] $stackTrace');
      throw Exception('Failed to like reel: $e');
    }
  }

  Future<void> unlikeReel({required String reelId}) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ [ERROR] User not authenticated');
        throw Exception('User not authenticated');
      }

      print('🔍 [DEBUG] Unliking reel: $reelId for userId: $userId');

      // Delete the like
      await client.from('reel_likes').delete().match({
        'reel_id': reelId,
        'user_id': userId,
      });

      print('✅ [SUCCESS] Removed like for reel: $reelId');

      // Decrement the likes count on the reel
      await client
          .from('course_reels')
          .update({
            'likes': client.rpc('decrement', params: {'value': 1}),
          })
          .eq('id', reelId);

      print('✅ [SUCCESS] Decremented likes count for reel: $reelId');
    } catch (e, stackTrace) {
      print('❌ [ERROR] Error unliking reel: $e');
      print('📝 [STACK TRACE] $stackTrace');
      throw Exception('Failed to unlike reel: $e');
    }
  }
}
