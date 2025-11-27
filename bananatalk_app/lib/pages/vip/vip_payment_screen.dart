import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/services/vip_service.dart';

class VipPaymentScreen extends StatefulWidget {
  final String userId;
  final VipPlan plan;

  const VipPaymentScreen({
    Key? key,
    required this.userId,
    required this.plan,
  }) : super(key: key);

  @override
  State<VipPaymentScreen> createState() => _VipPaymentScreenState();
}

class _VipPaymentScreenState extends State<VipPaymentScreen> {
  String? selectedPaymentMethod;
  bool isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'paypal',
      'name': 'PayPal',
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'google_pay',
      'name': 'Google Pay',
      'icon': Icons.payment,
    },
    {
      'id': 'apple_pay',
      'name': 'Apple Pay',
      'icon': Icons.apple,
    },
  ];

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    // Simulate payment processing
    // In a real app, you would integrate with a payment provider here
    await Future.delayed(const Duration(seconds: 2));

    // Call the VIP activation API
    final result = await VipService.activateVip(
      userId: widget.userId,
      plan: widget.plan,
      paymentMethod: selectedPaymentMethod!,
    );

    setState(() {
      isProcessing = false;
    });

    if (result['success']) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to VIP!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your VIP subscription is now active. Enjoy all premium features!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Start Exploring'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Plan Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.plan.displayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '\$${widget.plan.price}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plan.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...paymentMethods.map((method) {
                    return _buildPaymentMethodCard(
                      id: method['id'],
                      name: method['name'],
                      icon: method['icon'],
                    );
                  }).toList(),
                ],
              ),
            ),

            // Terms and Conditions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'By completing this purchase, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless cancelled.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Pay Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Pay \$${widget.plan.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String name,
    required IconData icon,
  }) {
    final isSelected = selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: id,
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value;
                });
              },
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
