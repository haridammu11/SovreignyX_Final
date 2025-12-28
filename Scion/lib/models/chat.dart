class ChatRoom {
  final int id;
  final String name;
  final String? description;
  final List<int> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    List<int> members = [];
    if (json['members'] != null) {
      members = List<int>.from(json['members']);
    }

    return ChatRoom(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      memberIds: members,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': memberIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Message {
  final int id;
  final int roomId;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['room'],
      senderId: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room': roomId,
      'sender': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class PrivateChat {
  final int id;
  final int user1Id;
  final int user2Id;
  final DateTime createdAt;

  PrivateChat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  factory PrivateChat.fromJson(Map<String, dynamic> json) {
    return PrivateChat(
      id: json['id'],
      user1Id: json['user1'],
      user2Id: json['user2'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1': user1Id,
      'user2': user2Id,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PrivateMessage {
  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  PrivateMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory PrivateMessage.fromJson(Map<String, dynamic> json) {
    return PrivateMessage(
      id: json['id'],
      chatId: json['chat'],
      senderId: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat': chatId,
      'sender': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class AssignmentProgress {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String status;
  final double progressPercentage;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentProgress({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.progressPercentage,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentProgress.fromJson(Map<String, dynamic> json) {
    return AssignmentProgress(
      id: json['id'],
      userId: json['user'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      progressPercentage: json['progress_percentage'].toDouble(),
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'title': title,
      'description': description,
      'status': status,
      'progress_percentage': progressPercentage,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
