class UserActivity {
  final int id;
  final int user;
  final String activityType;
  final String description;
  final DateTime timestamp;

  UserActivity({
    required this.id,
    required this.user,
    required this.activityType,
    required this.description,
    required this.timestamp,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'],
      user: json['user'],
      activityType: json['activity_type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'activity_type': activityType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class UserProgress {
  final int id;
  final int user;
  final int course;
  final double progressPercentage;
  final DateTime lastAccessed;

  UserProgress({
    required this.id,
    required this.user,
    required this.course,
    required this.progressPercentage,
    required this.lastAccessed,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'],
      user: json['user'],
      course: json['course'],
      progressPercentage: json['progress_percentage'].toDouble(),
      lastAccessed: DateTime.parse(json['last_accessed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'course': course,
      'progress_percentage': progressPercentage,
      'last_accessed': lastAccessed.toIso8601String(),
    };
  }
}

class QuizAnalytics {
  final int id;
  final int user;
  final int quiz;
  final int score;
  final double timeTaken;
  final DateTime attemptedAt;

  QuizAnalytics({
    required this.id,
    required this.user,
    required this.quiz,
    required this.score,
    required this.timeTaken,
    required this.attemptedAt,
  });

  factory QuizAnalytics.fromJson(Map<String, dynamic> json) {
    return QuizAnalytics(
      id: json['id'],
      user: json['user'],
      quiz: json['quiz'],
      score: json['score'],
      timeTaken: json['time_taken'].toDouble(),
      attemptedAt: DateTime.parse(json['attempted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'quiz': quiz,
      'score': score,
      'time_taken': timeTaken,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }
}

class EngagementMetric {
  final int id;
  final int user;
  final int totalActivities;
  final int streakDays;
  final double averageTimePerSession;
  final DateTime lastActive;

  EngagementMetric({
    required this.id,
    required this.user,
    required this.totalActivities,
    required this.streakDays,
    required this.averageTimePerSession,
    required this.lastActive,
  });

  factory EngagementMetric.fromJson(Map<String, dynamic> json) {
    return EngagementMetric(
      id: json['id'],
      user: json['user'],
      totalActivities: json['total_activities'],
      streakDays: json['streak_days'],
      averageTimePerSession: json['average_time_per_session'].toDouble(),
      lastActive: DateTime.parse(json['last_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'total_activities': totalActivities,
      'streak_days': streakDays,
      'average_time_per_session': averageTimePerSession,
      'last_active': lastActive.toIso8601String(),
    };
  }
}

class PerformanceMetric {
  final int id;
  final int user;
  final double overallScore;
  final int coursesCompleted;
  final int quizzesPassed;
  final DateTime lastUpdated;

  PerformanceMetric({
    required this.id,
    required this.user,
    required this.overallScore,
    required this.coursesCompleted,
    required this.quizzesPassed,
    required this.lastUpdated,
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      id: json['id'],
      user: json['user'],
      overallScore: json['overall_score'].toDouble(),
      coursesCompleted: json['courses_completed'],
      quizzesPassed: json['quizzes_passed'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'overall_score': overallScore,
      'courses_completed': coursesCompleted,
      'quizzes_passed': quizzesPassed,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
