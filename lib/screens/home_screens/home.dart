import 'package:adboard/modals/ad_modal.dart';
import 'package:adboard/screens/home_screens/ad_details.dart';
import 'package:adboard/screens/home_screens/notification.dart';
import 'package:adboard/screens/home_screens/search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  Stream<List<AdModel>>? _adsStream;
  List<AdModel>? _cachedAds;
  final TextEditingController _searchController = TextEditingController();
  bool _hasUnreadNotifications = false;
  int _unreadNotificationCount = 0;
  bool _showAllAds = false;
  static const String _cachedAdsKey = 'cached_ads';
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedAds();
    _initializeAdsStream();
    _checkUnreadNotifications();
  }

  void _loadCachedAds() {
    final cachedAdsJson = _prefs.getString(_cachedAdsKey);
    if (cachedAdsJson != null) {
      try {
        final List<dynamic> decodedAds = jsonDecode(cachedAdsJson);
        _cachedAds = decodedAds.map((ad) => AdModel.fromJson(ad)).toList();
        print('Loaded ${_cachedAds!.length} ads from cache');
      } catch (e) {
        print('Error loading cached ads: $e');
        _cachedAds = null;
      }
    }
  }

  Future<void> _saveCachedAds(List<AdModel> ads) async {
    try {
      final adsJson = jsonEncode(ads.map((ad) => ad.toJson()).toList());
      await _prefs.setString(_cachedAdsKey, adsJson);
      print('Saved ${ads.length} ads to cache');
    } catch (e) {
      print('Error saving cached ads: $e');
    }
  }

  void _initializeAdsStream() {
    _adsStream = FirebaseFirestore.instance
        .collectionGroup('userPosts')
        .snapshots()
        .asyncMap((snapshot) async {
      // Check if we have cached ads and if the data has changed
      if (_cachedAds != null) {
        bool hasChanges = false;
        
        // Check for changes in existing ads
        for (var doc in snapshot.docs) {
          final newAd = AdModel.fromFirestore(doc);
          final existingAd = _cachedAds!.firstWhere(
            (ad) => ad.id == newAd.id,
            orElse: () => newAd,
          );
          
          if (existingAd.toMap().toString() != newAd.toMap().toString()) {
            hasChanges = true;
            break;
          }
        }
        
        // Check for new or deleted ads
        if (!hasChanges && _cachedAds!.length != snapshot.docs.length) {
          hasChanges = true;
        }
        
        // If no changes, return cached ads
        if (!hasChanges) {
          return _cachedAds!;
        }
      }

      // Process new data
      List<AdModel> ads = [];
      for (var doc in snapshot.docs) {
        final ad = AdModel.fromFirestore(doc);
        
        if (!ad.availability) {
          final bookingSnapshot = await FirebaseFirestore.instance
              .collectionGroup('user-book-ads')
              .where('adId', isEqualTo: ad.id)
              .where('status', isEqualTo: 'Approved')
              .limit(1)
              .get();

          if (bookingSnapshot.docs.isNotEmpty) {
            final bookingData = bookingSnapshot.docs.first.data();
            final bookingTimestamp = DateTime.parse(bookingData['bookingTimestamp']);
            final durationDays = int.parse(bookingData['durationDays']);
            final bookingEndDate = bookingTimestamp.add(Duration(days: durationDays));

            if (DateTime.now().isAfter(bookingEndDate)) {
              await FirebaseFirestore.instance
                  .collection('ads')
                  .doc(ad.userId)
                  .collection('userPosts')
                  .doc(ad.id)
                  .update({'availability': true});
                  
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
            await FirebaseFirestore.instance
                .collection('ads')
                .doc(ad.userId)
                .collection('userPosts')
                .doc(ad.id)
                .update({'availability': true});
                
            final updatedDoc = await FirebaseFirestore.instance
                .collection('ads')
                .doc(ad.userId)
                .collection('userPosts')
                .doc(ad.id)
                .get();
                
            ads.add(AdModel.fromFirestore(updatedDoc));
          }
        } else {
          ads.add(ad);
        }
      }
      
      // Update cache
      _cachedAds = ads;
      _saveCachedAds(ads);
      return ads;
    });
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get bookings where user is the owner
      final ownerBookings = await FirebaseFirestore.instance
          .collection('booking')
          .doc(userId)
          .collection('user-book-ads')
          .get();

      // Get bookings where user is the booker
      final bookerBookings = await FirebaseFirestore.instance
          .collectionGroup('user-book-ads')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        _unreadNotificationCount = ownerBookings.docs.length + bookerBookings.docs.length;
        _hasUnreadNotifications = _unreadNotificationCount > 0;
      });
    } catch (e) {
      print('Error checking bookings: $e');
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
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _checkUnreadNotifications();
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
                            // Get current ads from stream
                            final adsList = await _adsStream?.first ?? [];
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
            StreamBuilder<List<AdModel>>(
              stream: _adsStream,
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
                              _initializeAdsStream();
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
