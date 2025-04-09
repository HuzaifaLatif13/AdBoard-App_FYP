import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  final String id;
  final String userId;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final double amount;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? notes;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.notes,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      bankName: data['bankName'] ?? '',
      accountName: data['accountName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      processedAt: data['processedAt'] != null
          ? DateTime.parse(data['processedAt'])
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
