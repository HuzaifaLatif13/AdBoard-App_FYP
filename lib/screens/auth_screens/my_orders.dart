import 'package:adboard/screens/home_screens/ad_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../modals/ad_modal.dart';
import '../home_screens/my_ads.dart';

class MyOrderScreen extends StatefulWidget {
  const MyOrderScreen({Key? key}) : super(key: key);

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> {
  late Future<List<AdModel>> userAds;

  @override
  void initState() {
    super.initState();
    userAds = fetchBookedAds();
  }

  Future<List<AdModel>> fetchBookedAds() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    List<AdModel> bookedAds = [];
    print(currentUserId);

    // Search all bookings to check if the current user is a booker
    QuerySnapshot allBookingsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('user-book-ads')
        .get();

    for (var doc in allBookingsSnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] == currentUserId) {
      print(data['adId']);
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .doc(data['adOwnerId']) // Document for the current user
          .collection('userPosts') // Subcollection for user's ads
          .doc(data['adId'])
          .get();
      if (snapshot.exists) {
        AdModel ad = AdModel.fromFirestore(snapshot);
        bookedAds.add(ad);
      }
    }
    }
    print('ENd');


    return bookedAds;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            userAds = fetchBookedAds();
          });
        },
        color: Colors.black,
        child: Scaffold(
          appBar: AppBar(
            elevation: 2,
            backgroundColor: Colors.white,
            title: const Text(
              'My Booked Ads',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: FutureBuilder<List<AdModel>>(
            future: userAds,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Failed to load ads.'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No ads found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              } else {
                final ads = snapshot.data!;
                final runningAds = ads.toList();

                return runningAds.isNotEmpty
                    ? ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: runningAds.length,
                  itemBuilder: (context, index) {
                    final ad = runningAds[index];
                    return GestureDetector(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdDetailsScreen(ad: ad),
                          ),
                        );
                        },
                      child: PostedAdCard(
                        ad: ad,
                        status: ad.availability ? 'Pending' : 'Published',
                      ),
                    );
                  },
                )
                    : const Center(
                  child: Text(
                    'No running ads.',
                    style:
                    TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}