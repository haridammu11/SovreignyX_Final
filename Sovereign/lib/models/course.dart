class Category {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Course {
  final int id;
  final String title;
  final String description;
  final int categoryId;
  final int instructorId;
  final String? thumbnail;
  final double price;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.instructorId,
    this.thumbnail,
    required this.price,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      categoryId: json['category'],
      instructorId: json['instructor'],
      thumbnail: json['thumbnail'],
      price: json['price'].toDouble(),
      isPublished: json['is_published'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': categoryId,
      'instructor': instructorId,
      'thumbnail': thumbnail,
      'price': price,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Module {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      courseId: json['course'],
      title: json['title'],
      description: json['description'],
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course': courseId,
      'title': title,
      'description': description,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Lesson {
  final int id;
  final int moduleId;
  final String title;
  final String content;
  final String? videoUrl;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.videoUrl,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      moduleId: json['module'],
      title: json['title'],
      content: json['content'],
      videoUrl: json['video_url'],
      order: json['order'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module': moduleId,
      'title': title,
      'content': content,
      'video_url': videoUrl,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Enrollment {
  final int id;
  final int userId;
  final int courseId;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final double progress;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    this.completedAt,
    required this.progress,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'],
      userId: json['user'],
      courseId: json['course'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
      progress: json['progress'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'course': courseId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }
}
