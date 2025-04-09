import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../modals/ad_modal.dart';
import '../widgets/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<List<AdModel>> ads;

  @override
  void initState() {
    super.initState();
    ads = fetchAds();
  }
  Future<List<AdModel>> fetchAds() async {
    print('\n\n\n\n\t\t\t\tFetching ads...3');
    try {
      // Query all documents from userPosts
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('userPosts')
          .get();

      if (snapshot.docs.isEmpty) {
        print('No ads found.');
        return [];
      }

      List<AdModel> ads = [];
      
      // Process each ad
      for (var doc in snapshot.docs) {
        final ad = AdModel.fromFirestore(doc);
        
        // If ad is marked as unavailable (booked), check if booking has expired
        if (!ad.availability) {
          // Fetch the latest approved booking for this ad
          // print(ad.id);
          // print(ad.userId);
          // print(ad.availability);
          final bookingSnapshot = await FirebaseFirestore.instance
              .collectionGroup('user-book-ads')
              .where('adId', isEqualTo: ad.id)
              .where('status', isEqualTo: 'Approved')
              .limit(1)
              .get();
          // print(bookingSnapshot.docs.length);

          if (bookingSnapshot.docs.isNotEmpty) {
            final bookingData = bookingSnapshot.docs.first.data();
            final bookingTimestamp = DateTime.parse(bookingData['bookingTimestamp']);
            final durationDays = int.parse(bookingData['durationDays']);
            final bookingEndDate = bookingTimestamp.add(Duration(days: durationDays));

            print('Checking ad: ${ad.title}');
            print('Booking end date: $bookingEndDate');
            print('Current date: ${DateTime.now()}');

            // If booking has expired, update ad availability
            if (DateTime.now().isAfter(bookingEndDate)) {
              print('Booking expired for ad: ${ad.title}');
              await FirebaseFirestore.instance
                  .collection('ads')
                  .doc(ad.userId)
                  .collection('userPosts')
                  .doc(ad.id)
                  .update({'availability': true});
                  
              // Update the ad object to reflect the new availability
              final updatedDoc = await FirebaseFirestore.instance
                  .collection('ads')
                  .doc(ad.userId)
                  .collection('userPosts')
                  .doc(ad.id)
                  .get();
                  
              ads.add(AdModel.fromFirestore(updatedDoc));
            } else {
              ads.add(ad);
            }
          } else {
            // No approved booking found, mark as available
            print('No approved booking found for ad: ${ad.title}');
            await FirebaseFirestore.instance
                .collection('ads')
                .doc(ad.userId)
                .collection('userPosts')
                .doc(ad.id)
                .update({'availability': true});
                
            // Add updated ad
            final updatedDoc = await FirebaseFirestore.instance
                .collection('ads')
                .doc(ad.userId)
                .collection('userPosts')
                .doc(ad.id)
                .get();
                
            ads.add(AdModel.fromFirestore(updatedDoc));
          }
        } else {
          // Ad is already available, just add it to the list
          ads.add(ad);
        }
      }

      print('Processed ${ads.length} ads.');
      return ads;
    } catch (e) {
      print('Error fetching ads: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainNavigationScreen(ads: ads,); // Loads the bottom nav structure
  }
}
