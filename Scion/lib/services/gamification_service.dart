import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class GamificationService {
  final SupabaseService _supabaseService = SupabaseService();

  late final SupabaseClient _supabase = _supabaseService.client;

  // ======================== POINTS ========================

  // Add points to user
  Future<void> addPoints(
    String userId,
    int amount,
    String reason, {
    String? courseId,
    String? relatedId,
  }) async {
    try {
      await _supabase.from('points').insert({
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'course_id': courseId,
        'related_id': relatedId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print(
        '[GamificationService] Added $amount points to $userId for: $reason',
      );
    } catch (e) {
      print('[GamificationService] Error adding points: $e');
      rethrow;
    }
  }

  // Get user's total points
  Future<int> getUserTotalPoints(String userId) async {
    try {
      final response = await _supabase
          .from('points')
          .select('amount')
          .eq('user_id', userId);

      int total = 0;
      for (var record in response) {
        total += record['amount'] as int;
      }

      return total;
    } catch (e) {
      print('[GamificationService] Error fetching total points: $e');
      return 0;
    }
  }

  // Get points history
  Future<List<Map<String, dynamic>>> getPointsHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('points')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching points history: $e');
      return [];
    }
  }

  // ======================== ACHIEVEMENTS ========================

  // Get all available achievements
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .order('points_required', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching achievements: $e');
      return [];
    }
  }

  // Get user's achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching user achievements: $e');
      return [];
    }
  }

  // Unlock an achievement
  Future<bool> unlockAchievement(String userId, String achievementId) async {
    try {
      // Check if already unlocked
      final existing =
          await _supabase
              .from('user_achievements')
              .select()
              .eq('user_id', userId)
              .eq('achievement_id', achievementId)
              .maybeSingle();

      if (existing != null) {
        print('[GamificationService] Achievement already unlocked');
        return false;
      }

      await _supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      print('[GamificationService] Achievement unlocked: $achievementId');
      return true;
    } catch (e) {
      print('[GamificationService] Error unlocking achievement: $e');
      return false;
    }
  }

  // Check if user has achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    try {
      final response =
          await _supabase
              .from('user_achievements')
              .select()
              .eq('user_id', userId)
              .eq('achievement_id', achievementId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      print('[GamificationService] Error checking achievement: $e');
      return false;
    }
  }

  // ======================== STREAKS ========================

  // Get user's current streak
  Future<Map<String, dynamic>?> getUserStreak(
    String userId,
    String courseId,
  ) async {
    try {
      final response =
          await _supabase
              .from('user_streaks')
              .select()
              .eq('user_id', userId)
              .eq('course_id', courseId)
              .maybeSingle();

      return response;
    } catch (e) {
      print('[GamificationService] Error fetching streak: $e');
      return null;
    }
  }

  // Update or create streak
  Future<void> updateStreak(String userId, String courseId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get current streak
      final existing =
          await _supabase
              .from('user_streaks')
              .select()
              .eq('user_id', userId)
              .eq('course_id', courseId)
              .maybeSingle();

      if (existing == null) {
        // Create new streak
        await _supabase.from('user_streaks').insert({
          'user_id': userId,
          'course_id': courseId,
          'current_streak': 1,
          'best_streak': 1,
          'last_activity': now.toIso8601String(),
          'created_at': now.toIso8601String(),
        });

        print('[GamificationService] Streak created for $userId in $courseId');
      } else {
        // Check if activity was today
        final lastActivity = DateTime.parse(existing['last_activity']);
        final lastActivityDate = DateTime(
          lastActivity.year,
          lastActivity.month,
          lastActivity.day,
        );

        int newStreak = existing['current_streak'];

        // If activity wasn't today, increment streak
        if (lastActivityDate.isBefore(today)) {
          newStreak = existing['current_streak'] + 1;
        }

        // Update best streak if current is higher
        int bestStreak = existing['best_streak'];
        if (newStreak > bestStreak) {
          bestStreak = newStreak;
        }

        await _supabase
            .from('user_streaks')
            .update({
              'current_streak': newStreak,
              'best_streak': bestStreak,
              'last_activity': now.toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('course_id', courseId);

        print('[GamificationService] Streak updated: $newStreak days');

        // Award streak bonuses
        if (newStreak == 7) {
          await addPoints(userId, 50, 'streak_7_days', courseId: courseId);
        } else if (newStreak == 14) {
          await addPoints(userId, 100, 'streak_14_days', courseId: courseId);
        } else if (newStreak == 30) {
          await addPoints(userId, 200, 'streak_30_days', courseId: courseId);
          await unlockAchievement(userId, 'streak_champion');
        }
      }
    } catch (e) {
      print('[GamificationService] Error updating streak: $e');
      rethrow;
    }
  }

  // Reset streak (after 1 day of inactivity)
  Future<void> resetStreak(String userId, String courseId) async {
    try {
      await _supabase
          .from('user_streaks')
          .update({
            'current_streak': 0,
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('course_id', courseId);

      print('[GamificationService] Streak reset for $userId');
    } catch (e) {
      print('[GamificationService] Error resetting streak: $e');
      rethrow;
    }
  }

  // ======================== LEADERBOARD ========================

  // Get global leaderboard
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('user_leaderboard')
          .select()
          .order('total_points', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching global leaderboard: $e');
      return [];
    }
  }

  // Get course leaderboard
  Future<List<Map<String, dynamic>>> getCourseLeaderboard(
    String courseId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('course_leaderboard')
          .select()
          .eq('course_id', courseId)
          .order('course_points', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching course leaderboard: $e');
      return [];
    }
  }

  // Get streak leaderboard
  Future<List<Map<String, dynamic>>> getStreakLeaderboard({
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('user_streaks')
          .select(
            'user_id, current_streak, best_streak, users(id, email, full_name)',
          )
          .order('current_streak', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[GamificationService] Error fetching streak leaderboard: $e');
      return [];
    }
  }

  // Get user's rank
  Future<int?> getUserRank(String userId) async {
    try {
      final leaderboard = await getGlobalLeaderboard(limit: 10000);
      final rank =
          leaderboard.indexWhere((entry) => entry['user_id'] == userId) + 1;

      return rank > 0 ? rank : null;
    } catch (e) {
      print('[GamificationService] Error fetching user rank: $e');
      return null;
    }
  }

  // ======================== LEVELS ========================

  // Calculate user level based on points
  int calculateLevel(int totalPoints) {
    // Level thresholds
    const List<int> thresholds = [
      0, // Level 1
      100, // Level 2
      300, // Level 3
      600, // Level 4
      1000, // Level 5
      1500, // Level 6
      2100, // Level 7
      2800, // Level 8
      3600, // Level 9
      5000, // Level 10+
    ];

    int level = 1;
    for (int i = 0; i < thresholds.length; i++) {
      if (totalPoints >= thresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }

    return level;
  }

  // Get points needed for next level
  int getPointsForNextLevel(int totalPoints) {
    const List<int> thresholds = [
      0,
      100,
      300,
      600,
      1000,
      1500,
      2100,
      2800,
      3600,
      5000,
    ];

    for (int threshold in thresholds) {
      if (totalPoints < threshold) {
        return threshold - totalPoints;
      }
    }

    // After level 10, each level needs 500 more points
    final level = calculateLevel(totalPoints);
    final nextThreshold = 5000 + ((level - 10) * 500);
    return nextThreshold - totalPoints;
  }

  // Get all levels configuration
  List<Map<String, dynamic>> getLevelsConfiguration() {
    return [
      {'level': 1, 'points': 0, 'title': 'Beginner', 'badge': '🌱'},
      {'level': 2, 'points': 100, 'title': 'Explorer', 'badge': '🔍'},
      {'level': 3, 'points': 300, 'title': 'Learner', 'badge': '📚'},
      {'level': 4, 'points': 600, 'title': 'Scholar', 'badge': '🎓'},
      {'level': 5, 'points': 1000, 'title': 'Master', 'badge': '⭐'},
      {'level': 6, 'points': 1500, 'title': 'Expert', 'badge': '🚀'},
      {'level': 7, 'points': 2100, 'title': 'Sage', 'badge': '🧙'},
      {'level': 8, 'points': 2800, 'title': 'Mentor', 'badge': '🎯'},
      {'level': 9, 'points': 3600, 'title': 'Legend', 'badge': '👑'},
      {'level': 10, 'points': 5000, 'title': 'Luminary', 'badge': '✨'},
    ];
  }

  // ======================== POINTS SOURCES ========================

  // Standard point values for different activities
  static const pointsMap = {
    'lesson_complete': 10,
    'quiz_pass_70': 50,
    'quiz_pass_90': 100,
    'quiz_pass_100': 150,
    'post_create': 5,
    'post_like': 1,
    'post_comment': 2,
    'help_user': 10,
    'streak_7_days': 50,
    'streak_14_days': 100,
    'streak_30_days': 200,
    'achievement_unlock': 25,
  };

  // Award points for quiz completion
  Future<void> awardQuizPoints(
    String userId,
    String quizId,
    int percentage, {
    required String courseId,
  }) async {
    int points = 0;
    String reason = '';

    if (percentage >= 90) {
      points = pointsMap['quiz_pass_100']!;
      reason = 'quiz_pass_100';
    } else if (percentage >= 70) {
      points = pointsMap['quiz_pass_90']!;
      reason = 'quiz_pass_90';
    }

    if (points > 0) {
      await addPoints(
        userId,
        points,
        reason,
        courseId: courseId,
        relatedId: quizId,
      );
    }
  }

  // Award points for lesson completion
  Future<void> awardLessonPoints(
    String userId,
    String lessonId, {
    required String courseId,
  }) async {
    await addPoints(
      userId,
      pointsMap['lesson_complete']!,
      'lesson_complete',
      courseId: courseId,
      relatedId: lessonId,
    );
  }
}
