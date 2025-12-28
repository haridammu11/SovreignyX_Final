class Quiz {
  final int id;
  final String title;
  final String? description;
  final int courseId;
  final int? lessonId;
  final Duration? timeLimit;
  final double passingScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    this.lessonId,
    this.timeLimit,
    required this.passingScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      courseId: json['course'],
      lessonId: json['lesson'],
      timeLimit:
          json['time_limit'] != null
              ? Duration(seconds: json['time_limit'])
              : null,
      passingScore: json['passing_score'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course': courseId,
      'lesson': lessonId,
      'time_limit': timeLimit?.inSeconds,
      'passing_score': passingScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Question {
  final int id;
  final int quizId;
  final String text;
  final String questionType;
  final double points;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.quizId,
    required this.text,
    required this.questionType,
    required this.points,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz'],
      text: json['text'],
      questionType: json['question_type'],
      points: json['points'].toDouble(),
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz': quizId,
      'text': text,
      'question_type': questionType,
      'points': points,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Choice {
  final int id;
  final int questionId;
  final String text;
  final bool isCorrect;
  final int order;

  Choice({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
    required this.order,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'],
      questionId: json['question'],
      text: json['text'],
      isCorrect: json['is_correct'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': questionId,
      'text': text,
      'is_correct': isCorrect,
      'order': order,
    };
  }
}

class UserQuizAttempt {
  final int id;
  final int userId;
  final int quizId;
  final double? score;
  final bool passed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Duration? timeTaken;

  UserQuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    this.score,
    required this.passed,
    required this.startedAt,
    this.completedAt,
    this.timeTaken,
  });

  factory UserQuizAttempt.fromJson(Map<String, dynamic> json) {
    return UserQuizAttempt(
      id: json['id'],
      userId: json['user'],
      quizId: json['quiz'],
      score: json['score']?.toDouble(),
      passed: json['passed'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      timeTaken:
          json['time_taken'] != null
              ? Duration(seconds: json['time_taken'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'quiz': quizId,
      'score': score,
      'passed': passed,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'time_taken': timeTaken?.inSeconds,
    };
  }
}
