class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePicture;
  final String? bio;
  final bool isVerified;
  final bool isPrivate;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profilePicture,
    this.bio,
    required this.isVerified,
    this.isPrivate = false,
    this.points = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String?,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'profile_picture': profilePicture,
      'bio': bio,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserProfile {
  final String id;
  final String userId;  // Changed from int to String
  final String? university;
  final String? department;
  final int? yearOfStudy;
  final String? enrollmentNumber;
  final DateTime? dateOfBirth;
  final String? address;
  final int streak;
  final DateTime lastActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.university,
    this.department,
    this.yearOfStudy,
    this.enrollmentNumber,
    this.dateOfBirth,
    this.address,
    required this.streak,
    required this.lastActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user'] as String,  // Changed from int to String
      university: json['university'] as String?,
      department: json['department'] as String?,
      yearOfStudy: json['year_of_study'] as int?,
      enrollmentNumber: json['enrollment_number'] as String?,
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null,
      address: json['address'] as String?,
      streak: json['streak'] as int? ?? 0,
      lastActive:
          json['last_active'] != null
              ? DateTime.parse(json['last_active'] as String)
              : DateTime.now(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'university': university,
      'department': department,
      'year_of_study': yearOfStudy,
      'enrollment_number': enrollmentNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'streak': streak,
      'last_active': lastActive.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
