import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check and update expired bookings
  Future<void> checkAndUpdateExpiredBookings() async {
    try {
      // Get all approved bookings
      final querySnapshot = await _firestore
          .collectionGroup('user-book-ads')
          .where('status', isEqualTo: 'Approved')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingTimestamp = DateTime.parse(data['bookingTimestamp']);
        final durationDays = int.parse(data['durationDays']);
        final bookingEndDate = bookingTimestamp.add(Duration(days: durationDays));

        // If booking has expired
        if (DateTime.now().isAfter(bookingEndDate)) {
          // Update booking status to expired
          await doc.reference.update({'status': 'Expired'});

          // Update ad availability to true
          await _firestore
              .collection('ads')
              .doc(data['adOwnerId'])
              .collection('userPosts')
              .doc(data['adId'])
              .update({'availability': true});
        }
      }
    } catch (e) {
      print('Error checking expired bookings: $e');
    }
  }

  // Start periodic check for expired bookings
  static void startExpiryCheck() {
    const duration = Duration(hours: 1); // Check every hour
    Future.doWhile(() async {
      try {
        final service = BookingService();
        await service.checkAndUpdateExpiredBookings();
      } catch (e) {
        print('Error in booking expiry check: $e');
      }
      await Future.delayed(duration);
      return true; // Continue the loop
    });
  }
} 