import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';

class PaymentService {
  static const String baseUrl =
      'https://9qcb6b3j-8000.inc1.devtunnels.ms/api/payments/';
  final String? token;

  PaymentService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  // Get all subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final url = Uri.parse('${baseUrl}plans/'); // Remove the extra slash
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscription plans');
    }
  }

  // Get user subscriptions
  Future<List<UserSubscription>> getUserSubscriptions(int userId) async {
    final url = Uri.parse('$baseUrl/subscriptions/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserSubscription.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user subscriptions');
    }
  }

  // Subscribe to a plan
  Future<UserSubscription> subscribeToPlan({
    required int userId,
    required int planId,
    required String paymentId,
  }) async {
    final url = Uri.parse('$baseUrl/subscriptions/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'user': userId,
        'plan': planId,
        'payment_id': paymentId,
        'start_date': DateTime.now().toIso8601String(),
        'end_date':
            DateTime.now()
                .add(Duration(days: 30))
                .toIso8601String(), // Assuming 30-day plan
        'is_active': true,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserSubscription.fromJson(data);
    } else {
      throw Exception('Failed to subscribe to plan');
    }
  }

  // Get payment history
  Future<List<Payment>> getPaymentHistory(int userId) async {
    final url = Uri.parse('$baseUrl/history/?user=$userId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payment history');
    }
  }

  // Process a payment
  Future<Payment> processPayment({
    required int userId,
    int? courseId,
    int? subscriptionId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String transactionId,
  }) async {
    final url = Uri.parse('$baseUrl/process/');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'user': userId,
        'course': courseId,
        'subscription': subscriptionId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'status': 'COMPLETED',
        'payment_date': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Payment.fromJson(data);
    } else {
      throw Exception('Failed to process payment');
    }
  }
}
