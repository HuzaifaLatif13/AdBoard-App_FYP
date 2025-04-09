import 'package:flutter/material.dart';
import 'package:adboard/services/payment_service.dart';

class TestPaymentScreen extends StatefulWidget {
  const TestPaymentScreen({Key? key}) : super(key: key);

  @override
  State<TestPaymentScreen> createState() => _TestPaymentScreenState();
}

class _TestPaymentScreenState extends State<TestPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController(text: '500.0');
  bool _isProcessing = false;
  String _resultMessage = '';

  @override
  void dispose() {
    _accountNumberController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processTestPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _resultMessage = '';
    });

    try {
      // Create a test payment record
      final payment = await _paymentService.createPayment(
        adId: 'test_ad_${DateTime.now().millisecondsSinceEpoch}',
        advertiserUserId: 'test_advertiser',
        amount: double.parse(_amountController.text),
      );

      // Process the payment
      final success = await _paymentService.processPayment(
        accountNumber: _accountNumberController.text,
        email: _emailController.text,
        amount: double.parse(_amountController.text),
        paymentId: payment.id,
      );

      setState(() {
        _resultMessage = success
            ? 'Payment processed successfully!'
            : 'Payment failed. Please try again.';
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Test Instructions
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Payment Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      '1. Enter any valid mobile number (11 digits)\n'
                      '2. Use any valid email address\n'
                      '3. Default amount is set to Rs. 500\n'
                      '4. Payment has 90% success rate for testing',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Account Number Field
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  }
                  if (value.length != 11) {
                    return 'Mobile number must be 11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // Process Payment Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _processTestPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Process Test Payment',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              // Result Message
              if (_resultMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _resultMessage.contains('successfully')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _resultMessage,
                      style: TextStyle(
                        color: _resultMessage.contains('successfully')
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
