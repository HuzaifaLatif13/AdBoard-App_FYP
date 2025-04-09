import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String adId;
  final String userId;
  final String advertiserUserId;
  final double amount;
  final String status; // 'pending', 'completed', 'failed', 'expired'
  final String transactionId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime dueDate;

  PaymentModel({
    required this.id,
    required this.adId,
    required this.userId,
    required this.advertiserUserId,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    this.paidAt,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adId': adId,
      'userId': userId,
      'advertiserUserId': advertiserUserId,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      adId: map['adId'] ?? '',
      userId: map['userId'] ?? '',
      advertiserUserId: map['advertiserUserId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      dueDate: DateTime.parse(map['dueDate']),
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromMap({...data, 'id': doc.id});
  }
}
