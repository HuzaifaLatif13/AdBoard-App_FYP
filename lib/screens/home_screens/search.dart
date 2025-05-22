import 'package:adboard/screens/auth_screens/account.dart';
import 'package:adboard/screens/auth_screens/edit_account.dart';
import 'package:adboard/screens/form_screens/post_ad.dart';
import 'package:adboard/screens/home_screens/home.dart';
import 'package:adboard/screens/home_screens/my_ads.dart';
import 'package:flutter/material.dart';
import 'package:adboard/widgets/adcard.dart';
import 'package:adboard/modals/ad_modal.dart';
import 'package:adboard/screens/home_screens/ad_details.dart';
import 'package:adboard/modals/filter_model.dart';
import 'package:adboard/widgets/filter_dialog.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<AdModel> ads;
  final String query;

  const SearchResultsScreen({Key? key, required this.ads, required this.query})
      : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String sortBy = 'relevance';
  late List<AdModel> filteredAds;
  FilterModel currentFilters = FilterModel();
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  // Predefined lists for filters
  final List<String> categories = ['Billboards', 'Transit', 'In-Store'];
  final List<String> sizes = ['Small', 'Medium', 'Large'];

  String getSizeCategory(String dimensions) {
    try {
      // Extract numbers from dimensions string (e.g., "10x5" -> [10, 5])
      final numbers = dimensions.split('x').map((e) => double.parse(e.trim())).toList();
      if (numbers.length != 2) return 'Medium'; // Default to Medium if format is invalid
      
      final width = numbers[0];
      final height = numbers[1];
      final area = width * height;

      if (area <= 50) { // 10x5 = 50
        return 'Small';
      } else if (area <= 200) { // 16x8 = 128, 12x6 = 72, 18x4 = 72, 10x6 = 60
        return 'Medium';
      } else { // 40x20 = 800
        return 'Large';
      }
    } catch (e) {
      return 'Medium'; // Default to Medium if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _currentSearchQuery = widget.query;
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      filteredAds = widget.ads.where((ad) {
        // Text search filter
        bool matchesSearch = _currentSearchQuery.isEmpty ||
            ad.title
                .toLowerCase()
                .contains(_currentSearchQuery.toLowerCase()) ||
            ad.description
                .toLowerCase()
                .contains(_currentSearchQuery.toLowerCase()) ||
            ad.category
                .toLowerCase()
                .contains(_currentSearchQuery.toLowerCase()) ||
            ad.location
                .toLowerCase()
                .contains(_currentSearchQuery.toLowerCase());

        // Location filter
        bool matchesLocation = currentFilters.location == null ||
            ad.location
                .toLowerCase()
                .contains(currentFilters.location!.toLowerCase());

        // Price range filter
        bool matchesPrice = true;
        if (currentFilters.minPrice != null) {
          double adPrice =
              double.tryParse(ad.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          matchesPrice = matchesPrice && adPrice >= currentFilters.minPrice!;
        }
        if (currentFilters.maxPrice != null) {
          double adPrice =
              double.tryParse(ad.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          matchesPrice = matchesPrice && adPrice <= currentFilters.maxPrice!;
        }

        // Category filter
        bool matchesCategory = currentFilters.category == null ||
            ad.category == currentFilters.category;

        // Availability filter
        bool matchesAvailability = currentFilters.isAvailable == null ||
            ad.availability == currentFilters.isAvailable;

        // Size filter
        bool matchesSize = currentFilters.size == null ||
            getSizeCategory(ad.size) == currentFilters.size;

        // Date range filter
        bool matchesDateRange = true;
        if (currentFilters.postedAfter != null) {
          matchesDateRange = matchesDateRange &&
              DateTime.parse(ad.datePosted)
                  .isAfter(currentFilters.postedAfter!);
        }
        if (currentFilters.postedBefore != null) {
          matchesDateRange = matchesDateRange &&
              DateTime.parse(ad.datePosted)
                  .isBefore(currentFilters.postedBefore!);
        }

        return matchesSearch &&
            matchesLocation &&
            matchesPrice &&
            matchesCategory &&
            matchesAvailability &&
            matchesSize &&
            matchesDateRange;
      }).toList();
    });
  }

  List<AdModel> getSortedAds() {
    List<AdModel> sortedAds = List.from(filteredAds);

    try {
      if (sortBy == 'price_low') {
        sortedAds.sort((a, b) =>
            _getPriceAsInt(a.price).compareTo(_getPriceAsInt(b.price)));
      } else if (sortBy == 'price_high') {
        sortedAds.sort((a, b) =>
            _getPriceAsInt(b.price).compareTo(_getPriceAsInt(a.price)));
      }
    } catch (e) {
      debugPrint('Error sorting ads: $e');
    }

    return sortedAds;
  }

  int _getPriceAsInt(String price) {
    final numericPrice = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), ''));
    return numericPrice ?? 0;
  }

  void updateSearchResults(String query) {
    setState(() {
      _currentSearchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<FilterModel>(
      context: context,
      builder: (context) => FilterDialog(
        currentFilters: currentFilters,
        categories: categories,
        sizes: sizes,
      ),
    );

    if (result != null) {
      setState(() {
        currentFilters = result;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<AdModel> sortedAds = getSortedAds();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for ads...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                        prefixIcon: const Icon(Icons.search, color: Colors.black87, size: 26),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      onChanged: updateSearchResults,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8.0, right: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.filter_list_outlined,
                              color: Colors.black87, size: 26),
                          if (currentFilters.hasActiveFilters())
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: const Text(
                                  '!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _showFilterDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentSearchQuery.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Results for "${_currentSearchQuery}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text(
                        'Relevance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text(
                        'Price: Low to High',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text(
                        'Price: High to Low',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                  },
                  underline: const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedAds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (currentFilters.hasActiveFilters())
                          TextButton(
                            onPressed: () {
                              setState(() {
                                currentFilters = currentFilters.clear();
                                _applyFilters();
                              });
                            },
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: sortedAds.length,
                    itemBuilder: (context, index) {
                      final ad = sortedAds[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdDetailsScreen(ad: ad),
                            ),
                          );
                        },
                        child: AdCard(
                          imageUrl: ad.imageUrls[0],
                          price: ad.price,
                          title: ad.title,
                          category: ad.category,
                          location: ad.location,
                          postedTimestamp: ad.datePosted,
                          name: ad.userName,
                          isAvailable: ad.availability,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
