import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final int userId;
  final String? token;
  final int? courseId;
  final int? subscriptionPlanId;

  const PaymentScreen({
    super.key,
    required this.userId,
    this.token,
    this.courseId,
    this.subscriptionPlanId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentService _paymentService;
  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selectedPlan;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _errorMessage = '';
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(token: widget.token);
    _loadSubscriptionPlans();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      final plans = await _paymentService.getSubscriptionPlans();
      setState(() {
        _plans = plans;
        if (widget.subscriptionPlanId != null) {
          _selectedPlan = plans.firstWhere(
            (plan) => plan.id == widget.subscriptionPlanId,
            orElse: () => plans.first,
          );
        } else if (plans.isNotEmpty) {
          _selectedPlan = plans.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPlan == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // In a real app, you would integrate with a payment gateway like Stripe or PayPal
      // For this demo, we'll simulate a successful payment

      // Generate a fake transaction ID
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';

      // Process the payment
      await _paymentService.processPayment(
        userId: widget.userId,
        courseId: widget.courseId,
        subscriptionId: _selectedPlan!.id,
        amount: _selectedPlan!.price,
        currency: 'USD',
        paymentMethod: 'CREDIT_CARD',
        transactionId: transactionId,
      );

      // Subscribe to the plan
      await _paymentService.subscribeToPlan(
        userId: widget.userId,
        planId: _selectedPlan!.id,
        paymentId: transactionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));

        // Navigate back or to a success screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseId != null ? 'Purchase Course' : 'Subscribe to Plan',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSubscriptionPlans,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purchase details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (widget.courseId != null)
                              const Text(
                                'Course: Introduction to Flutter Development',
                              ),
                            if (_selectedPlan != null) ...[
                              const SizedBox(height: 5),
                              Text('Plan: ${_selectedPlan!.name}'),
                              const SizedBox(height: 5),
                              Text(
                                'Price: \$${_selectedPlan!.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subscription plan selection (if not purchasing a specific course)
                    if (widget.courseId == null) ...[
                      const Text(
                        'Select Subscription Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(plan.name),
                              subtitle: Text(plan.description),
                              trailing: Text(
                                '\$${plan.price.toStringAsFixed(2)}',
                              ),
                              selected: _selectedPlan?.id == plan.id,
                              onTap: () {
                                setState(() {
                                  _selectedPlan = plan;
                                });
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment method
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _cardHolderController,
                              decoration: const InputDecoration(
                                labelText: 'Cardholder Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _cardNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _expiryController,
                                    decoration: const InputDecoration(
                                      labelText: 'MM/YY',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _cvvController,
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_selectedPlan?.price.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Pay button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isProcessing
                                ? const Text('Processing...')
                                : const Text('Pay Now'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
