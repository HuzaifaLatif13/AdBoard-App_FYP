import 'package:adboard/modals/payment_model.dart';
import 'package:adboard/modals/withdrawal_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../const/keys.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;
  static String secretKey = stripeSecretKey; // Replace with your Stripe secret key

  // Test credentials for Easypaisa sandbox
  static const String _testStoreId =
      'TEST_STORE_ID'; // Replace with your test store ID
  static const String _testHashKey =
      'TEST_HASH_KEY'; // Replace with your test hash key
  static const String _testAccountNum = '03123456789';


  // Create a new payment record
  Future<PaymentModel> createPayment({
    required String adId,
    required String advertiserUserId,
    required double amount,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      // Create a new document reference to get the ID
      final paymentRef = _firestore.collection('payments').doc();
      final paymentId = paymentRef.id;

      // Create the payment document with the generated ID
      await paymentRef.set({
        'id': paymentId, // Save the ID in the document
        'adId': adId,
        'userId': advertiserUserId,
        'advertiserUserId': userId,
        'amount': amount,
        'status': 'pending',
        'transactionId': '',
        'createdAt': DateTime.now().toIso8601String(),
        'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      return PaymentModel.fromFirestore(await paymentRef.get());
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  // Process payment using Stripe
  Future<bool> processPayment({
    required double amount,
    required PaymentModel payment,
  }) async {
    try {
      print('Processing payment for amount: $amount');
      // Convert amount to paisa (multiply by 100) and then to string
      final amountInPaisa = (amount * 100 ).round().toString();
      await paymentSheetInitialization(amountInPaisa, 'pkr');

      // Update payment status
      await _firestore.collection('payments').doc(payment.id).update({
        'status': 'done',
        'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // Update advertiser balance (we'll deduct our commission here - 10%)
      final commission = amount * 0.10;
      final advertiserAmount = amount - commission;
      await updateAdvertiserBalance(payment.advertiserUserId, advertiserAmount);

      // Update booking status to Approved after successful payment
      final bookingSnapshot = await _firestore
          .collection('booking')
          .doc(payment.advertiserUserId)
          .collection('user-book-ads')
          .where('adId', isEqualTo: payment.adId)
          .where('userId', isEqualTo: payment.userId)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        final bookingDoc = bookingSnapshot.docs.first;
        await bookingDoc.reference.update({'status': 'Approved'});

        // Update ad availability
        await _firestore
            .collection('ads')
            .doc(payment.advertiserUserId)
            .collection('userPosts')
            .doc(payment.adId)
            .update({
          'availability': false,
          'paymentPending': false,
        });

        // Create a notification for successful payment and booking approval
        await _firestore.collection('notifications').add({
          'userId': payment.userId,
          'title': 'Payment Successful',
          'message': 'Your payment has been processed and your booking is now approved.',
          'type': 'payment_success',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> makeIntentPayment(String chargedAmount, String currency) async {
    try {
      // chargedAmount is already in paisa as a string
      print('Amount in paisa: $chargedAmount');
      Map<String, dynamic> paymentSheetParameters = {
        "amount": chargedAmount,
        "currency": currency.toLowerCase(), // Stripe expects lowercase currency code
        "payment_method_types[]": "card",
      };
      
      var responseStripeAPI = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: paymentSheetParameters,
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-Type": "application/x-www-form-urlencoded"
        }
      );
      
      if (responseStripeAPI.statusCode == 200) {
        return jsonDecode(responseStripeAPI.body);
      } else {
        print('Failed with status: ${responseStripeAPI.statusCode}');
        print('Response body: ${responseStripeAPI.body}');
        return null;
      }
    } catch (errorMsg) {
      if (kDebugMode) {
        print(errorMsg);
      }
      print(errorMsg.toString());
      return null;
    }
  }

  Future<void> paymentSheetInitialization(String chargedAmount, String currency) async {
    try {
      final intentPaymentData = await makeIntentPayment(chargedAmount, currency);
      if (intentPaymentData == null) throw 'Failed to create payment intent';

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          allowsDelayedPaymentMethods: true,
          paymentIntentClientSecret: intentPaymentData['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: 'AdBoard',
        )
      );

      await showPaymentSheet();
    } catch (errorMsg, e) {
      if (kDebugMode) {
        print(e);
      }
      print(errorMsg.toString());
      rethrow;
    }
  }

  Future<void> showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      rethrow;
    } catch (errorMsg, e) {
      if (kDebugMode) {
        print(e);
      }
      print(errorMsg.toString());
      rethrow;
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return PaymentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting payment: $e');
      return null;
    }
  }

  // Get user's pending payments
  Future<List<PaymentModel>> getPendingPayments() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      print('Getting pending payments for user: $userId');

      final querySnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      print('Pending payments: ${querySnapshot.docs.length}');

      return querySnapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pending payments: $e');
      return [];
    }
  }

  // Get dummy pending payments for testing
  List<PaymentModel> getDummyPendingPayments() {
    return [
      PaymentModel(
        id: '1',
        adId: 'ad1',
        userId: 'user1',
        advertiserUserId: 'advertiser1',
        amount: 500.0,
        status: 'pending',
        transactionId: '',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      PaymentModel(
        id: '2',
        adId: 'ad2',
        userId: 'user1',
        advertiserUserId: 'advertiser2',
        amount: 300.0,
        status: 'pending',
        transactionId: '',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 6)),
      ),
    ];
  }

  // Get advertiser's current balance
  Future<double> getAdvertiserBalance() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0.0;

      final balanceDoc =
          await _firestore.collection('advertiser_balances').doc(userId).get();

      if (!balanceDoc.exists) {
        // Initialize balance if it doesn't exist
        await _firestore
            .collection('advertiser_balances')
            .doc(userId)
            .set({'balance': 0.0});
        return 0.0;
      }

      return (balanceDoc.data()?['balance'] ?? 0.0).toDouble();
    } catch (e) {
      print('Error getting advertiser balance: $e');
      return 0.0;
    }
  }

  // Update advertiser balance when payment is received
  Future<void> updateAdvertiserBalance(String advertiserUserId, double amount) async {
    try {
      final balanceRef =
          _firestore.collection('advertiser_balances').doc(advertiserUserId);

      await _firestore.runTransaction((transaction) async {
        final balanceDoc = await transaction.get(balanceRef);
        final currentBalance =
            (balanceDoc.data()?['balance'] ?? 0.0).toDouble();

        transaction.set(
          balanceRef,
          {'balance': currentBalance + amount},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print('Error updating advertiser balance: $e');
      rethrow;
    }
  }

  // Request withdrawal
  Future<WithdrawalModel> requestWithdrawal({required String bankName,
    required String accountName,
    required String accountNumber,
    required double amount,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      // Check if user has sufficient balance
      final currentBalance = await getAdvertiserBalance();
      if (currentBalance < amount) {
        throw 'Insufficient balance';
      }

      // Create withdrawal request
      final withdrawalDoc = await _firestore.collection('withdrawals').add({
        'userId': userId,
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'amount': amount,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Deduct amount from balance
      await _firestore.runTransaction((transaction) async {
        final balanceRef =
            _firestore.collection('advertiser_balances').doc(userId);

        final balanceDoc = await transaction.get(balanceRef);
        final currentBalance =
            (balanceDoc.data()?['balance'] ?? 0.0).toDouble();

        if (currentBalance < amount) {
          throw 'Insufficient balance';
        }

        transaction.set(
          balanceRef,
          {'balance': currentBalance - amount},
          SetOptions(merge: true),
        );
      });

      return WithdrawalModel.fromFirestore(await withdrawalDoc.get());
    } catch (e) {
      print('Error requesting withdrawal: $e');
      rethrow;
    }
  }

  // Get user's withdrawal history
  Future<List<WithdrawalModel>> getWithdrawalHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Getting withdrawal history for user: $userId');
      if (userId == null) return [];

      final querySnapshot = await _firestore
          .collection('withdrawals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting withdrawal history: $e');
      return [];
    }
  }

  // Create a test payment notification and record
  Future<void> createTestPaymentNotification(String userId) async {
    try {
      // Create a test payment record
      final paymentDoc = await _firestore.collection('payments').add({
        'adId': 'test_ad_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'advertiserUserId': userId, // Same user is advertiser for testing
        'amount': 5000.0, // Test amount of 5000
        'status': 'pending',
        'transactionId': '',
        'createdAt': DateTime.now().toIso8601String(),
        'dueDate':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      // Create a test notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Test Payment Required',
        'message': 'Please complete the test payment of Rs. 5000',
        'type': 'payment',
        'paymentId': paymentDoc.id,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });

      // Create a test booking record
      await _firestore
          .collection('booking')
          .doc(userId)
          .collection('user-book-ads')
          .add({
        'adId': 'test_ad_${DateTime.now().millisecondsSinceEpoch}',
        'adOwnerId': userId,
        'adTitle': 'Test Advertisement',
        'userId': userId,
        'userName': 'Test User',
        'userEmail': 'test@example.com',
        'amount': '5000',
        'status': 'Approved',
        'bookingTimestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating test payment notification: $e');
      rethrow;
    }
  }

  // Add test balance for testing
  Future<void> addTestBalance(double amount) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'User not authenticated';

      final userDoc = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);

        double currentBalance = 0.0;
        if (snapshot.exists) {
          currentBalance = (snapshot.data()?['balance'] ?? 0.0).toDouble();
        }

        transaction.set(
          userDoc,
          {'balance': currentBalance + amount},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      print('Error adding test balance: $e');
      rethrow;
    }
  }

  // Check and handle expired payments
  Future<void> checkExpiredPayments() async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in querySnapshot.docs) {
        final payment = PaymentModel.fromFirestore(doc);
        if (DateTime.now().isAfter(payment.dueDate)) {
          // Update payment status to expired
          await doc.reference.update({'status': 'expired'});

          // Get the booking details
          final bookingSnapshot = await _firestore
              .collection('booking')
              .doc(payment.advertiserUserId)
              .collection('user-book-ads')
              .where('adId', isEqualTo: payment.adId)
              .where('userId', isEqualTo: payment.userId)
              .get();

          if (bookingSnapshot.docs.isNotEmpty) {
            final bookingDoc = bookingSnapshot.docs.first;
            // Update booking status to expired
            await bookingDoc.reference.update({'status': 'Expired'});

            // Set ad availability back to true
            await _firestore
                .collection('ads')
                .doc(payment.advertiserUserId)
                .collection('userPosts')
                .doc(payment.adId)
                .update({'availability': true});
          }
        }
      }
    } catch (e) {
      print('Error checking expired payments: $e');
      rethrow;
    }
  }

  // Schedule periodic check for expired payments
  static void startExpiryCheck() {
    const duration = Duration(hours: 1); // Check every hour
    Future.doWhile(() async {
      try {
        final service = PaymentService();
        await service.checkExpiredPayments();
      } catch (e) {
        print('Error in payment expiry check: $e');
      }
      await Future.delayed(duration);
      return true; // Continue the loop
    });
  }
}
