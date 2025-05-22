import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:adboard/services/payment_service.dart';
import 'package:adboard/screens/payment_screens/payment_screen.dart';
import 'package:shimmer/shimmer.dart';

class NotificationScreen extends StatefulWidget {
  final String userId; // Current logged-in owner's ID

  NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PaymentService _paymentService = PaymentService();

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      List<Map<String, dynamic>> notifications = [];

      // Fetch bookings for the logged-in owner
      QuerySnapshot ownerSnapshot = await FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.userId) // Owner's document
          .collection('user-book-ads') // Subcollection of bookings
          .get();

      // Add bookings to the list if the user is the owner
      notifications.addAll(ownerSnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'role': 'Owner',
        ...doc.data() as Map<String, dynamic>
      })
          .toList());

      // Search all bookings to check if the current user is a booker
      QuerySnapshot allBookingsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('user-book-ads')
          .get();

      for (var doc in allBookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] == widget.userId) {
          // Add bookings to the list if the user is the booker
          notifications.add({'id': doc.id, 'role': 'Booker', ...data});
        }
      }

      notifications.sort((a, b) {
        DateTime timestampA = DateTime.parse(a['bookingTimestamp']);
        DateTime timestampB = DateTime.parse(b['bookingTimestamp']);
        return timestampB.compareTo(timestampA);
      });

      return notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      // First check in the owner's bookings
      DocumentSnapshot? bookingDoc;
      Map<String, dynamic>? bookingData;

      // Check in owner's bookings first
      bookingDoc = await FirebaseFirestore.instance
          .collection('booking')
          .doc(widget.userId)
          .collection('user-book-ads')
          .doc(bookingId)
          .get();

      if (bookingDoc.exists) {
        bookingData = bookingDoc.data() as Map<String, dynamic>;
      } else {
        // If not found in owner's bookings, search in all bookings
        QuerySnapshot bookingQuery = await FirebaseFirestore.instance
            .collectionGroup('user-book-ads')
            .where(FieldPath.documentId, isEqualTo: bookingId)
            .get();

        if (bookingQuery.docs.isNotEmpty) {
          bookingDoc = bookingQuery.docs.first;
          bookingData = bookingDoc.data() as Map<String, dynamic>;
        }
      }

      if (bookingDoc == null || !bookingDoc.exists || bookingData == null) {
        throw 'Booking not found';
      }

      if (status == 'Approved' || status == 'Pending Payment') {
        // Create payment record
        print('adid: ${bookingData['adId']}, advertiserUserId: ${bookingData['adOwnerId']}, amount: ${bookingData['totalAmount']}');
        final payment = await _paymentService.createPayment(
          adId: bookingData['adId'],
          advertiserUserId: bookingData['userId'],
          amount: double.parse(bookingData['totalAmount']?.toString() ?? '0'),
        );

        //update booking status to Pending Payment
        bookingDoc.reference.update({'status': 'Pending Payment'});

        // Create payment notification for the user
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': bookingData['userId'],
          'title': 'Payment Required',
          'message':
          'Your booking request has been accepted. Please complete the payment within 7 days to confirm your booking.',
          'type': 'payment',
          'paymentId': payment.id,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        });

        // Set the availability of the ad to pending-payment
        await FirebaseFirestore.instance
            .collection('ads')
            .doc(bookingData['adOwnerId'])
            .collection('userPosts')
            .doc(bookingData['adId'])
            .update({
          'availability': false,
          'paymentPending': true,
          'bookingId': bookingId, // Add bookingId reference
        });

        // Start payment expiry check
        PaymentService.startExpiryCheck();
      } else if (status == 'Rejected') {
        // For rejected status, update ad availability
        await FirebaseFirestore.instance
            .collection('ads')
            .doc(bookingData['adOwnerId'])
            .collection('userPosts')
            .doc(bookingData['adId'])
            .update({
          'availability': true,
          'paymentPending': false,
          'bookingId': null, // Clear bookingId reference
        });
      }
      // Create a status update notification for the booker
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': bookingData['userId'],
        'title': 'Booking Request Update',
        'message':
        'Your booking request for ${bookingData['adTitle']} has been $status.',
        'type': 'booking_status',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error updating booking status or ad availability: $e');
      rethrow;
    }
  }

  void showBookingDetailsDialog(
      BuildContext context, Map<String, dynamic> booking) {
    bool isAccepting = false;
    bool isRejecting = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Request for ${booking['adTitle']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requested by: ${booking['userName']}'),
                  const SizedBox(height: 8.0),
                  Text('Email: ${booking['userEmail']}'),
                  const SizedBox(height: 8.0),
                  Text('Duration: ${booking['durationDays']} days'),
                  const SizedBox(height: 8.0),
                  Text('Special Instructions: ${booking['specialInstructions']}'),
                          if (booking['adDesignUrl'] != null) ...[
                        const SizedBox(height: 16.0),
                        const Text('Ad Design:'),
                        const SizedBox(height: 8.0),
                            FutureBuilder<void>(
                              future: precacheImage(
                                NetworkImage(booking['adDesignUrl']),
                                context,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                                
                                if (snapshot.hasError) {
                                  return Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                }

                                return Image.network(
                                  booking['adDesignUrl'],
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                  onPressed: (isAccepting || isRejecting)
                      ? null
                      : () async {
                          setState(() => isRejecting = true);
                          try {
                            await updateBookingStatus(booking['id'], 'Rejected');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              this.setState(() {}); // Refresh screen
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isRejecting = false);
                            }
                          }
                        },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                  child: isRejecting
                      ? const SizedBox(
                                      height: 20,
                          width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                        )
                      : const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                  onPressed: (isAccepting || isRejecting)
                      ? null
                      : () async {
                          setState(() => isAccepting = true);
                          try {
                            await updateBookingStatus(booking['id'], 'Pending Payment');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              this.setState(() {}); // Refresh screen
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isAccepting = false);
                            }
                          }
                        },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                  child: isAccepting
                      ? const SizedBox(
                                      height: 20,
                          width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                        )
                      : const Text('Accept'),
                            ),
                          ),
                        ],
                ),
              ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String getTimeDifferenceFromNow(String timestamp) {
    DateTime bookingTime = DateTime.parse(timestamp);
    Duration difference = DateTime.now().difference(bookingTime);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds} seconds ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else if (difference.inDays < 30) {
      return "${(difference.inDays / 7).floor()} weeks ago";
    } else if (difference.inDays < 365) {
      return "${(difference.inDays / 30).floor()} months ago";
    } else {
      return "${(difference.inDays / 365).floor()} years ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No new notifications.'));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final booking = notifications[index];
              return Container(
                margin:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(booking['role'] == 'Owner'
                      ? 'Booking Request for ${booking['adTitle']}'
                      : 'Your Booking for ${booking['adTitle']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['role'] == 'Owner'
                          ? 'Requested by ${booking['userName']}'
                          : 'Status: ${booking['status']}'),
                      const SizedBox(height: 4.0),
                      Text(
                        getTimeDifferenceFromNow(booking['bookingTimestamp']),
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Text(
                    booking['status'],
                    style: TextStyle(
                      color: booking['status'] == 'Pending'
                          ? Colors.orange
                          : booking['status'] == 'Approved'
                          ? Colors.green
                          : booking['status'] == 'Pending Payment'
                          ? Colors.blue
                          : Colors.red,
                    ),
                  ),
                  onTap: () {
                    if (booking['role'] == 'Owner' && booking['status'] != 'Approved') {
                      showBookingDetailsDialog(context, booking);
                    } else {
                      // Handle payment notifications
                      if (booking['status'] == 'Pending Payment') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(),
                          ),
                        );
                      } else {
                        // Show status for other notifications
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Status: ${booking['status']}')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}