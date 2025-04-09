import 'package:adboard/modals/withdrawal_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WithdrawalRequestsScreen extends StatefulWidget {
  const WithdrawalRequestsScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalRequestsScreen> createState() =>
      _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<WithdrawalModel> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('withdrawals')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _withdrawals = querySnapshot.docs
            .map((doc) => WithdrawalModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading withdrawals: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWithdrawalStatus(
    String withdrawalId,
    String status,
    String? notes,
  ) async {
    try {
      await _firestore.collection('withdrawals').doc(withdrawalId).update({
        'status': status,
        'processedAt': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      });

      // If rejected, return the amount to user's balance
      if (status == 'rejected') {
        final withdrawal = _withdrawals.firstWhere((w) => w.id == withdrawalId);
        final balanceRef =
            _firestore.collection('advertiser_balances').doc(withdrawal.userId);

        await _firestore.runTransaction((transaction) async {
          final balanceDoc = await transaction.get(balanceRef);
          final currentBalance =
              (balanceDoc.data()?['balance'] ?? 0.0).toDouble();

          transaction.set(
            balanceRef,
            {'balance': currentBalance + withdrawal.amount},
            SetOptions(merge: true),
          );
        });
      }

      _loadWithdrawals();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Withdrawal ${status.toLowerCase()} successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating withdrawal: $e')),
      );
    }
  }

  Future<void> _showActionDialog(WithdrawalModel withdrawal) async {
    final notesController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: Rs. ${withdrawal.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Bank: ${withdrawal.bankName}'),
            Text('Account: ${withdrawal.accountNumber}'),
            Text('Name: ${withdrawal.accountName}'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this transaction',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateWithdrawalStatus(
                withdrawal.id,
                'rejected',
                notesController.text.isNotEmpty ? notesController.text : null,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateWithdrawalStatus(
                withdrawal.id,
                'approved',
                notesController.text.isNotEmpty ? notesController.text : null,
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWithdrawals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _withdrawals.isEmpty
              ? const Center(child: Text('No withdrawal requests'))
              : ListView.builder(
                  itemCount: _withdrawals.length,
                  itemBuilder: (context, index) {
                    final withdrawal = _withdrawals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                            Text('Bank: ${withdrawal.bankName}'),
                            Text('Account: ${withdrawal.accountNumber}'),
                            Text('Name: ${withdrawal.accountName}'),
                            Text(
                              'Requested: ${DateFormat('MMM d, yyyy').format(withdrawal.createdAt)}',
                            ),
                            if (withdrawal.notes != null)
                              Text(
                                'Notes: ${withdrawal.notes}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: withdrawal.status == 'pending'
                            ? ElevatedButton(
                                onPressed: () => _showActionDialog(withdrawal),
                                child: const Text('Process'),
                              )
                            : Chip(
                                label: Text(
                                  withdrawal.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: withdrawal.status == 'approved'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
