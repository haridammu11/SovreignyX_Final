import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social.dart';
import 'supabase_service.dart';

class SocialService {
  final String? token;
  final SupabaseService _supabaseService = SupabaseService();

  SocialService({this.token});

  // Get followers for a user
  Future<List<Follow>> getFollowers(String userId) async {
    try {
      // Convert int userId to String as Supabase uses UUID strings
      final followers = await _supabaseService.getFollowers(userId.toString());
      return followers;
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  // Get following for a user
  Future<List<Follow>> getFollowing(String userId) async {
    try {
      // Convert int userId to String as Supabase uses UUID strings
      final following = await _supabaseService.getFollowing(userId.toString());
      return following;
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }

  // Follow a user
  Future<Follow> followUser(String userId, String followedId) async {
    try {
      // Convert int userIds to Strings as Supabase uses UUID strings
      final follow = await _supabaseService.followUser(
        followerId: userId.toString(),
        followedId: followedId.toString(),
      );
      return follow;
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId, String followedId) async {
    try {
      // Convert int userIds to Strings as Supabase uses UUID strings
      await _supabaseService.unfollowUser(
        followerId: userId.toString(),
        followedId: followedId.toString(),
      );
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Get posts
  Future<List<Post>> getPosts() async {
    try {
      final posts = await _supabaseService.getPosts();
      return posts;
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }
  
  // Get user posts
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final posts = await _supabaseService.getUserPosts(userId);
      return posts;
    } catch (e) {
      throw Exception('Failed to load user posts: $e');
    }
  }

  // Create a post
  Future<Post> createPost({
    required String authorId,
    required String content,
    String? image,
  }) async {
    try {
      // Convert int authorId to String as Supabase uses UUID strings
      final post = await _supabaseService.createPost(
        authorId: authorId.toString(),
        content: content,
        imageUrl: image,
      );
      return post;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Like a post
  Future<void> likePost(int postId, String userId) async {
    try {
      // Convert int userId to String as Supabase uses UUID strings
      await _supabaseService.likePost(
        postId: postId,
        userId: userId.toString(),
      );
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Unlike a post
  Future<void> unlikePost(int postId, String userId) async {
    try {
      // Convert int userId to String as Supabase uses UUID strings
      await _supabaseService.unlikePost(
        postId: postId,
        userId: userId.toString(),
      );
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Get comments for a post
  Future<List<Comment>> getComments(int postId) async {
    try {
      final comments = await _supabaseService.getComments(postId);
      return comments;
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  // Create a comment
  Future<Comment> createComment({
    required int postId,
    required String authorId,
    required String content,
  }) async {
    try {
      // Convert int authorId to String as Supabase uses UUID strings
      final comment = await _supabaseService.createComment(
        postId: postId,
        authorId: authorId.toString(),
        content: content,
      );
      return comment;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  // Get achievements for a user
  Future<List<Achievement>> getAchievements(String userId) async {
    try {
      // Convert int userId to String as Supabase uses UUID strings
      final achievements = await _supabaseService.getAchievements(
        userId.toString(),
      );
      return achievements;
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }

  // Get leaderboard
  Future<List<Leaderboard>> getLeaderboard() async {
    try {
      final leaderboard = await _supabaseService.getLeaderboard();
      return leaderboard;
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  Future<Connection> createFollowRequest({
    required String requesterId,
    required String targetUserId,
  }) async {
    return _supabaseService.createFollowRequest(
      requesterId: requesterId,
      targetUserId: targetUserId,
    );
  }

  Future<List<Connection>> getPendingFollowRequests(String userId) async {
    return _supabaseService.getPendingFollowRequests(userId);
  }

  Future<int> getPendingFollowRequestsCount(String userId) async {
    return _supabaseService.getPendingFollowRequestsCount(userId);
  }

  Future<List<Connection>> getOutgoingFollowRequests(String userId) async {
    return _supabaseService.getOutgoingFollowRequests(userId);
  }

  Future<void> cancelOutgoingFollowRequest({
    required String requesterId,
    required String targetUserId,
  }) async {
    return _supabaseService.cancelOutgoingFollowRequest(
      requesterId: requesterId,
      targetUserId: targetUserId,
    );
  }

  Future<void> acceptFollowRequest(int requestId) async {
    return _supabaseService.acceptFollowRequest(requestId);
  }

  Future<void> rejectFollowRequest(int requestId) async {
    return _supabaseService.rejectFollowRequest(requestId);
  }
}
