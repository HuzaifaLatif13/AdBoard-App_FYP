import 'package:adboard/modals/ad_modal.dart';
import 'package:adboard/screens/home_screens/ad_details.dart';
import 'package:adboard/screens/home_screens/notification.dart';
import 'package:adboard/screens/home_screens/search.dart';
import 'package:adboard/screens/home_screens/all_ads.dart';
import 'package:adboard/widgets/adcard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  late Future<List<AdModel>> ads;
  final TextEditingController _searchController = TextEditingController();
  bool _hasUnreadNotifications = false;
  bool _showAllAds = false;

  @override
  void initState() {
    super.initState();
    ads = fetchAds();
  }

  // Future<List<AdModel>> fetchAds() async {
  //   try {
  //     print('Starting to fetch ads...');

  //     // Query all ads using collectionGroup without ordering
  //     QuerySnapshot snapshot =
  //         await FirebaseFirestore.instance.collectionGroup('userPosts').get();

  //     print('Found ${snapshot.docs.length} ads');

  //     if (snapshot.docs.isEmpty) {
  //       print('No ads found.');
  //       return [];
  //     }

  //     List<AdModel> adsList = [];

  //     for (var doc in snapshot.docs) {
  //       try {
  //         print('Processing ad: ${doc.id}');
  //         final ad = AdModel.fromFirestore(doc);
  //         print(ad.userId);
  //         adsList.add(ad);
  //       } catch (e) {
  //         print('Error parsing ad document ${doc.id}: $e');
  //         continue;
  //       }
  //     }

  //     // Sort the ads by datePosted manually
  //     adsList.sort((a, b) => b.datePosted.compareTo(a.datePosted));

  //     print('Successfully parsed ${adsList.length} total ads');
  //     return adsList;
  //   } catch (e) {
  //     print('Error in fetchAds: $e');
  //     return [];
  //   }
  // }

  Future<List<AdModel>> fetchAds() async {
    print('\n\n\n\n\t\t\t\tFetching ads...2');
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

            // print('Checking ad: ${ad.title}');
            // print('Booking end date: $bookingEndDate');
            // print('Current date: ${DateTime.now()}');

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'AdBoard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                    userId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              ).then((_) {
                setState(() {
                  ads = fetchAds();
                });
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            ads = fetchAds();
          });
        },
        color: Theme.of(context).primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for ads...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).primaryColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) async {
                          if (value.isNotEmpty) {
                            // Fetch ads before navigating to search
                            final adsList = await ads;
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(
                                    query: value,
                                    ads: adsList,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('All', selectedCategory == 'All'),
                          _buildCategoryChip(
                              'Billboards', selectedCategory == 'Billboards'),
                          _buildCategoryChip(
                              'Transit', selectedCategory == 'Transit'),
                          _buildCategoryChip(
                              'In-Store', selectedCategory == 'In-Store'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Featured Ads
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Ads',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllAds = !_showAllAds;
                            });
                          },
                          child: Text(_showAllAds ? 'Show Less' : 'See All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Ads Grid
            FutureBuilder<List<AdModel>>(
              future: ads,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading ads',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                ads = fetchAds();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.ad_units_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ads available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to post an ad!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/post-ad');
                            },
                            child: const Text('Post an Ad'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredAds = selectedCategory == 'All'
                    ? snapshot.data!
                    : snapshot.data!
                        .where((ad) => ad.category == selectedCategory)
                        .toList();

                // Limit the number of ads shown if not showing all
                final displayAds =
                    _showAllAds ? filteredAds : filteredAds.take(6).toList();

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ad = displayAds[index];
                        return _buildAdCard(context, ad);
                      },
                      childCount: displayAds.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              selectedCategory = isSelected ? 'All' : label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, AdModel ad) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdDetailsScreen(ad: ad),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ad.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  if (!ad.availability)
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Text(
                          'BOOKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.location,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
