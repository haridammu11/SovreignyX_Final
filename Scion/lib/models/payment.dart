class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    List<String> featuresList = [];
    if (json['features'] != null) {
      featuresList = List<String>.from(json['features']);
    }

    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      durationDays: json['duration_days'],
      features: featuresList,
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'features': features,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserSubscription {
  final int id;
  final int userId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user'],
      planId: json['plan'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'],
      paymentId: json['payment_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'plan': planId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'payment_id': paymentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Payment {
  final int id;
  final int userId;
  final int? courseId;
  final int? subscriptionId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final DateTime paymentDate;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.userId,
    this.courseId,
    this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.paymentDate,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['user'],
      courseId: json['course'],
      subscriptionId: json['subscription'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      status: json['status'],
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'course': courseId,
      'subscription': subscriptionId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
