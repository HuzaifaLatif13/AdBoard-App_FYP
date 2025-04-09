import 'package:adboard/modals/withdrawal_model.dart';
import 'package:adboard/services/payment_service.dart';
import 'package:adboard/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdvertiserPaymentsScreen extends StatefulWidget {
  const AdvertiserPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdvertiserPaymentsScreen> createState() =>
      _AdvertiserPaymentsScreenState();
}

class _AdvertiserPaymentsScreenState extends State<AdvertiserPaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();

  double _currentBalance = 0.0;
  List<WithdrawalModel> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final balance = await _paymentService.getAdvertiserBalance();
      final withdrawals = await _paymentService.getWithdrawalHistory();
      setState(() {
        _currentBalance = balance;
        _withdrawals = withdrawals;
      });
    } catch (e) {
      _notificationService.showErrorNotification(
        context,
        message: 'Error loading data',
        subtitle: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showWithdrawalDialog() async {
    // Reset controllers
    _bankNameController.clear();
    _accountNameController.clear();
    _accountNumberController.clear();
    _amountController.clear();

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Request Withdrawal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'Rs. ${_currentBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter bank name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNameController,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter account name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter account number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter amount';
                      final amount = double.tryParse(value!);
                      if (amount == null) return 'Invalid amount';
                      if (amount <= 0) return 'Amount must be greater than 0';
                      if (amount > _currentBalance) {
                        return 'Amount exceeds available balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _requestWithdrawal(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestWithdrawal(BuildContext dialogContext) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await _paymentService.requestWithdrawal(
        bankName: _bankNameController.text,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        amount: double.parse(_amountController.text),
      );

      // Close the dialog first
      Navigator.pop(dialogContext);

      // Only show notification if the widget is still mounted
      if (mounted) {
        _notificationService.showSuccessNotification(
          context,
          message: 'Withdrawal Request Submitted',
          subtitle: 'Your request will be processed within 24-48 hours',
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _notificationService.showErrorNotification(
          context,
          message: 'Error requesting withdrawal',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _addTestBalance() async {
    try {
      await _paymentService.addTestBalance(1000.0);
      if (mounted) {
        await _loadData();
        _notificationService.showTestNotifications(context);
      }
    } catch (e) {
      if (mounted) {
        _notificationService.showErrorNotification(
          context,
          message: 'Error adding test balance',
          subtitle: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Withdrawals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addTestBalance,
            tooltip: 'Add Test Balance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs. ${_currentBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _currentBalance > 0
                                      ? _showWithdrawalDialog
                                      : null,
                                  child: const Text('Request Withdrawal'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Withdrawal History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_withdrawals.isEmpty)
                        const Center(
                          child: Text('No withdrawal history'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _withdrawals.length,
                          itemBuilder: (context, index) {
                            final withdrawal = _withdrawals[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  'Rs. ${withdrawal.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(withdrawal.bankName),
                                    Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(withdrawal.createdAt),
                                    ),
                                  ],
                                ),
                                trailing: _buildStatusChip(withdrawal.status),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
