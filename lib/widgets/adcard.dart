import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdCard extends StatelessWidget {
  final String imageUrl;
  final String price;
  final String title;
  final String category;
  final String location;
  final String postedTimestamp;
  final String name;
  final bool isAvailable;

  const AdCard({
    super.key,
    required this.imageUrl,
    required this.price,
    required this.title,
    required this.category,
    required this.location,
    required this.postedTimestamp,
    required this.name,
    required this.isAvailable,
  });

  String getTimeDifferenceFromNow(String timestamp) {
    DateTime postedTime = DateTime.tryParse(timestamp) ?? DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error_outline, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Price
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                // Location and Category
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        location,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Text(
      category,
      style: const TextStyle(
        fontSize: 11,
        color: Colors.grey,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ],
),

                // const SizedBox(height: 2),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Expanded(
                //       child: Text(
                //         name,
                //         style: const TextStyle(
                //           fontSize: 11,
                //           color: Colors.grey,
                //         ),
                //         maxLines: 1,
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //     ),
                //     Container(
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: 4, vertical: 1),
                //       decoration: BoxDecoration(
                //         color: isAvailable
                //             ? Colors.green.withOpacity(0.1)
                //             : Colors.red.withOpacity(0.1),
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //       child: Text(
                //         isAvailable ? "Available" : "Booked",
                //         style: TextStyle(
                //           fontSize: 9,
                //           fontWeight: FontWeight.bold,
                //           color: isAvailable ? Colors.green : Colors.red,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
