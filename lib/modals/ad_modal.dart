import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final List<String> imageUrls;
  final String price;
  final double rating;
  final String title;
  final String category;
  final String location;
  final String datePosted;
  final String size;
  final bool availability;
  final String description;
  final String userName;
  final String userProfileImage;
  final String userContact;
  final String id; // Ad ID
  final String userId; // Owner's user ID

  AdModel({
    required this.imageUrls,
    required this.price,
    required this.rating,
    required this.title,
    required this.category,
    required this.location,
    required this.datePosted,
    required this.size,
    required this.availability,
    required this.description,
    required this.userName,
    required this.userProfileImage,
    required this.userContact,
    required this.id,
    required this.userId,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      price: data['price'] ?? '0',
      rating: (data['rating'] ?? 0.0).toDouble(),
      title: data['title'] ?? 'Untitled',
      category: data['category'] ?? 'Other',
      location: data['location'] ?? 'Location not specified',
      datePosted: data['datePosted'] ?? DateTime.now().toIso8601String(),
      size: data['size'] ?? 'Size not specified',
      availability: data['availability'] ?? true,
      description: data['description'] ?? 'No description available',
      userName: data['userName'] ?? 'Anonymous',
      userProfileImage: data['userProfileImage'] ?? '',
      userContact: data['userContact'] ?? 'Contact not provided',
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrls': imageUrls,
      'price': price,
      'rating': rating,
      'title': title,
      'category': category,
      'location': location,
      'datePosted': datePosted,
      'size': size,
      'availability': availability,
      'description': description,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'userContact': userContact,
      'id': id,
      'userId': userId,
    };
  }

  //from map
  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      imageUrls: List<String>.from(map['imageUrls']),
      price: map['price'],
      rating: map['rating'],
      title: map['title'],
      category: map['category'],
      location: map['location'],
      datePosted: map['datePosted'],
      size: map['size'],
      availability: map['availability'],
      description: map['description'],
      userName: map['userName'],
      userProfileImage: map['userProfileImage'],
      userContact: map['userContact'],
      id: map['id'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel.fromMap(json);
  }
}

class Booking {
  final String bookingId;
  final String adId;
  final String adOwnerId;
  final String adTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String userContact;
  final String durationDays;
  final String amount;
  final String specialInstructions;
  final String adDesignUrl;
  final String bookingTimestamp;
  final String status;

  Booking({
    required this.bookingId,
    required this.adId,
    required this.adOwnerId,
    required this.adTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userContact,
    required this.durationDays,
    required this.amount,
    required this.specialInstructions,
    required this.adDesignUrl,
    required this.bookingTimestamp,
    required this.status,
  });

  // Factory constructor to create a Booking from a Firestore document/map
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      bookingId: map['bookingId'] ?? '',
      adId: map['adId'] ?? '',
      adOwnerId: map['adOwnerId'] ?? '',
      adTitle: map['adTitle'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userContact: map['userContact'] ?? '',
      durationDays: map['durationDays'] ?? '',
      amount: map['amount'] ?? '',
      specialInstructions: map['specialInstructions'] ?? '',
      adDesignUrl: map['adDesignUrl'] ?? '',
      bookingTimestamp: map['bookingTimestamp'] ?? '',
      status: map['status'] ?? 'Pending',
    );
  }

  // Method to convert Booking instance to a Map for saving in Firestore
  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'adId': adId,
      'adOwnerId': adOwnerId,
      'adTitle': adTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userContact': userContact,
      'durationDays': durationDays,
      'amount': amount,
      'specialInstructions': specialInstructions,
      'adDesignUrl': adDesignUrl,
      'bookingTimestamp': bookingTimestamp,
      'status': status,
    };
  }
}
