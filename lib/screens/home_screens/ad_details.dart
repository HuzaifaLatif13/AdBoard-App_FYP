import 'package:adboard/screens/form_screens/booking.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:adboard/modals/ad_modal.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdDetailsScreen extends StatefulWidget {
  final AdModel ad;

  const AdDetailsScreen({Key? key, required this.ad}) : super(key: key);

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  int _currentImageIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingAnalytics = true;
  bool _hasError = false;
  Map<String, String> _aiAnalytics = {
    'suggestion': '',
    'traffic': '',
    'peakHours': '',
  };

  @override
  void initState() {
    super.initState();
    _getAiAnalytics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String getTimeDifferenceFromNow(String timestamp) {
    DateTime postedTime = DateTime.parse(timestamp);
    Duration difference = DateTime.now().difference(postedTime);

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

  Future<Map<String, dynamic>?> fetchBookingDetails() async {
    try {
      final bookingSnapshot = await FirebaseFirestore.instance
          .collectionGroup('user-book-ads')
          .where('adId', isEqualTo: widget.ad.id)
          .where('status', isEqualTo: 'Approved')
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        return bookingSnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching booking details: $e');
      return null;
    }
  }

  Future<void> _getAiAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
      _hasError = false;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: 'AIzaSyCEyQVYuzJDzs8ZqFe8CHLScOVWXstuN1Q',
      );

      final prompt = '''
        Analyze this outdoor advertisement space and provide key business insights:
        Location: ${widget.ad.location}
        Price: ${widget.ad.price} PKR
        Type: ${widget.ad.category}
        Size: ${widget.ad.size}

        Provide exactly one short line (max 40 characters) for each:
        
        ROI Potential:
        [Estimate ROI potential as High/Medium/Low with brief reason]
        
        Daily Views:
        [Estimate daily views in numbers, e.g. "25K+ daily views"]
        
        Best Times:
        [Best 4-hour window for max visibility]
        
        Format:
        [Don't include ** or make words bold in response]
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final lines = response.text!.split('\n');
        String currentSection = '';
        Map<String, String> results = {
          'suggestion': '',
          'traffic': '',
          'peakHours': '',
        };

        for (var line in lines) {
          final roiMatch = RegExp(r'roi potential:\s*(.*)', caseSensitive: false).firstMatch(line);
          final viewsMatch = RegExp(r'daily views:\s*(.*)', caseSensitive: false).firstMatch(line);
          final timesMatch = RegExp(r'best times:\s*(.*)', caseSensitive: false).firstMatch(line);

          if (roiMatch != null) {
            results['suggestion'] = roiMatch.group(1)!.trim();
            currentSection = '';
          } else if (viewsMatch != null) {
            results['traffic'] = viewsMatch.group(1)!.trim();
            currentSection = '';
          } else if (timesMatch != null) {
            results['peakHours'] = timesMatch.group(1)!.trim();
            currentSection = '';
          } else if (line.trim().isNotEmpty && currentSection.isNotEmpty) {
            // fallback for value on next line
            String processedLine = line.trim();
            if (processedLine.length > 40) {
              processedLine = '${processedLine.substring(0, 37)}...';
            }
            results[currentSection] = processedLine;
            currentSection = '';
          }
        }

        setState(() {
          _aiAnalytics = results;
          _isLoadingAnalytics = false;
          _hasError = false;
        });
      } else {
        throw Exception('No response from AI');
      }
    } catch (e) {
      print('Error getting AI analytics: $e');
      setState(() {
        _isLoadingAnalytics = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: PageView.builder(
                        itemCount: widget.ad.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: 'ad_image_${widget.ad.id}',
                            child: CachedNetworkImage(
                              imageUrl: widget.ad.imageUrls[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Image counter
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${widget.ad.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.ad.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.ad.price,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Text(
                                    'per day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Location and Time
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.ad.location,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                  softWrap: true,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                getTimeDifferenceFromNow(widget.ad.datePosted),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick Info Cards
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildQuickInfoCard(
                                'Category',
                                widget.ad.category,
                                Icons.category,
                              ),
                              _buildQuickInfoCard(
                                'Size',
                                widget.ad.size,
                                Icons.aspect_ratio,
                              ),
                              _buildQuickInfoCard(
                                'Status',
                                widget.ad.availability ? 'Available' : 'Booked',
                                Icons.event_available,
                                color: widget.ad.availability
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            widget.ad.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Traffic Analytics
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Traffic Analytics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingAnalytics)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_hasError)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to load analytics',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _getAiAnalytics,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    _buildAnalyticsCard(
                                      'ROI Potential',
                                      _aiAnalytics['suggestion']?.isNotEmpty == true 
                                          ? _aiAnalytics['suggestion']! 
                                          : 'Unable to analyze ROI',
                                      Icons.trending_up,
                                    ),
                                    _buildAnalyticsCard(
                                      'Daily Views',
                                      _aiAnalytics['traffic']?.isNotEmpty == true
                                          ? _aiAnalytics['traffic']!
                                          : 'Traffic data unavailable',
                                      Icons.visibility,
                                    ),
                                    _buildAnalyticsCard(
                                      'Best Times',
                                      _aiAnalytics['peakHours']?.isNotEmpty == true
                                          ? _aiAnalytics['peakHours']!
                                          : 'Timing data unavailable',
                                      Icons.schedule,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Listed By
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Listed By',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: (widget.ad.userProfileImage !=
                                            null &&
                                        widget.ad.userProfileImage
                                            .trim()
                                            .isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        widget.ad.userProfileImage)
                                    : const CachedNetworkImageProvider(
                                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRCO2sR3EtGqpIpIa-GTVnvdrDHu0WxuzpA8g&s'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.ad.userName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.ad.userContact,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Book Now Button
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: FirebaseAuth.instance.currentUser?.uid == widget.ad.userId
                    ? null // Disable button if current user is the ad owner
                    : () async {
                        if (!widget.ad.availability) {
                          final bookingDetails = await fetchBookingDetails();
                          if (bookingDetails != null) {
                            _showBookingDetailsDialog(bookingDetails);
                          } else {
                            _navigateToBooking();
                          }
                        } else {
                          _navigateToBooking();
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.uid == widget.ad.userId
                          ? 'Your Ad'
                          : widget.ad.availability
                              ? 'Book Now'
                              : 'Check Availability',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAdScreen(ad: widget.ad),
      ),
    );
  }

  void _showBookingDetailsDialog(Map<String, dynamic> bookingDetails) {
    try {
      final duration = int.parse(bookingDetails['durationDays'] ?? '0');
      final bookingTimestampStr = bookingDetails['bookingTimestamp'] ?? '';

      if (bookingTimestampStr.isNotEmpty) {
        final bookingStartDate = DateTime.parse(bookingTimestampStr);
        final bookingEndDate = bookingStartDate.add(Duration(days: duration));
        var remainingDays = bookingEndDate.difference(DateTime.now()).inDays;
        //if zero, check for hours
        if (remainingDays == 0) {
          final remainingHours =
              bookingEndDate.difference(DateTime.now()).inHours;
          if (remainingHours > 0) {
            remainingDays = 1;
          } else {
            remainingDays = 0;
          }
        }

        print('Booking Start Date: $bookingStartDate');
        print('Booking End Date: $bookingEndDate');
        print('Now: ${DateTime.now()}');
        print('Remaining Days: $remainingDays');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remainingDays > 0
                      ? 'This ad space is currently booked.'
                      : 'This booking has expired.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBookingInfoRow(
                  'Start Date',
                  bookingStartDate.toString().split(' ')[0],
                ),
                _buildBookingInfoRow(
                  'End Date',
                  bookingEndDate.toString().split(' ')[0],
                ),
                _buildBookingInfoRow(
                  'Duration',
                  '$duration days',
                ),
                if (remainingDays > 0)
                  _buildBookingInfoRow(
                    'Remaining',
                    '$remainingDays days',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error showing booking details: $e');
    }
  }

  Widget _buildBookingInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(String title, String value, IconData icon,
      {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.grey[600], size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(
        minWidth: 140,
        maxWidth: 140,
        minHeight: 140,
        maxHeight: 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
