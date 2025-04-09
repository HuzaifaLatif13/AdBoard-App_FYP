import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:adboard/modals/ad_modal.dart';
import 'package:adboard/screens/form_screens/edit_ad.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({
    super.key,
  });

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  late Future<List<AdModel>> userAds;

  @override
  void initState() {
    super.initState();
    userAds = fetchUserAds();
  }

  Future<List<AdModel>> fetchUserAds() async {
    try {
      String currentUserId = user!.uid;

      // Query the user's userPosts subcollection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .doc(currentUserId) // Document for the current user
          .collection('userPosts') // Subcollection for user's ads
          .get();

      // Map the query results to a list of AdModel objects
      return snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching user ads: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          title: const Text(
            'My Ads',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),

          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Running'),
              Tab(text: 'UnPublished'), // Renamed from Completed to UnPublished
            ],
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
              final runningAds = ads.where((ad) => ad.availability).toList();
              final unpublishedAds =
                  ads.where((ad) => !ad.availability).toList();

              return TabBarView(
                children: [
                  // Running Ads
                  runningAds.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: runningAds.length,
                          itemBuilder: (context, index) {
                            final ad = runningAds[index];
                            return GestureDetector(
                              onTap: () async {
                                // Navigate to EditAdScreen and refresh on return
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAdScreen(ad: ad),
                                  ),
                                );
                                setState(() {
                                  userAds = fetchUserAds(); // Refresh data
                                });
                              },
                              child: PostedAdCard(
                                ad: ad,
                                status: 'Published',
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No running ads.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                  // UnPublished Ads
                  unpublishedAds.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: unpublishedAds.length,
                          itemBuilder: (context, index) {
                            final ad = unpublishedAds[index];
                            return GestureDetector(
                              onTap: () async {
                                // Allow editing of unpublished ads
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAdScreen(ad: ad),
                                  ),
                                );
                                setState(() {
                                  userAds = fetchUserAds(); // Refresh data
                                });
                              },
                              child: PostedAdCard(
                                ad: ad,
                                status: 'UnPublished', // Updated status
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No unpublished ads.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class PostedAdCard extends StatelessWidget {
  final AdModel ad;
  final String status;

  const PostedAdCard({
    Key? key,
    required this.ad,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ad Image
          Container(
            margin: const EdgeInsets.only(left: 2),
            child: Image.network(
              ad.imageUrls[0],
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12.0),
          // Ad Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    ad.size,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    ad.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ad Status
          Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color:
                  status == 'Published' ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: status == 'Published' ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
