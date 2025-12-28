class CourseReel {
  final String id;
  final String courseId;
  final String courseTitle;
  final String videoId;
  final String title;
  final String description;
  final String language;
  final int likes;
  final DateTime createdAt;

  CourseReel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.videoId,
    required this.title,
    required this.description,
    required this.language,
    required this.likes,
    required this.createdAt,
  });

  factory CourseReel.fromJson(Map<String, dynamic> json) {
    return CourseReel(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseTitle: json['course_title'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'English',
      likes: json['likes'] as int? ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_title': courseTitle,
      'video_id': videoId,
      'title': title,
      'description': description,
      'language': language,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
