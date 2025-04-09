import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:adboard/modals/ad_modal.dart';

class BookAdScreen extends StatefulWidget {

  final AdModel ad;

  const BookAdScreen({Key? key, required this.ad}) : super(key: key);

  @override
  State<BookAdScreen> createState() => _BookAdScreenState();
}

class _BookAdScreenState extends State<BookAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aboutAdController = TextEditingController();
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  XFile? _adDesign;
  bool isLoading = false;

  @override
  void dispose() {
    _aboutAdController.dispose();
    _specialInstructionsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickAdDesign() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _adDesign = pickedFile;
      });
    }
  }

// User Info
  String userName = 'Anonymous';
  String userEmail = 'Not Provided';
  String userContact = 'Not Provided';

  Future<void> fetchUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            userName = data['name'] ?? 'Anonymous';
            userEmail = data['email'] ?? 'Not Provided';
            userContact = data['phone'] ?? 'Not Provided';
          });
        } else {
          setState(() {
            userName = user.displayName ?? 'Anonymous';
            userEmail = user.email ?? 'Not Provided';
            userContact = user.phoneNumber ?? 'Not Provided';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user info: $e')),
      );
    }
  }

  Future<void> _sendBookingRequest() async {
    fetchUserInfo();
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Fetch current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw Exception('User not logged in');

        // Generate a unique booking ID
        final bookingId =
            FirebaseFirestore.instance.collection('booking').doc().id;

        // Upload Ad Design to Firebase Storage if provided
        String? adDesignUrl;
        if (_adDesign != null) {
          String fileName =
              'bookings/$bookingId${_adDesign!.path.split('/').last}';
          Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
          TaskSnapshot uploadTask =
              await storageRef.putFile(File(_adDesign!.path));
          adDesignUrl = await uploadTask.ref.getDownloadURL();
        }

        // Save Booking in Firestore
        await FirebaseFirestore.instance
            .collection('booking')
            .doc(widget.ad.userId)
            .collection('user-book-ads')
            .doc(bookingId)
            .set({
          'bookingId': bookingId,
          'adId': widget.ad.id,
          'adOwnerId': widget.ad.userId,
          'adTitle': widget.ad.title,
          'userId': currentUser.uid,
          'userName': userName,
          'userEmail': userEmail,
          'userContact': userContact,
          'durationDays': _durationController.text,
          'specialInstructions': _specialInstructionsController.text,
          'adDesignUrl': adDesignUrl,
          'bookingTimestamp': DateTime.now().toIso8601String(),
          'status': 'Pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Book Ad',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad Details Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8.0)),
                          child: Image.network(
                            widget.ad.imageUrls.isNotEmpty
                                ? widget.ad.imageUrls[0]
                                : 'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ad.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Location: ${widget.ad.location}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                'Size: ${widget.ad.size}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                'Price: ${widget.ad.price}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // About Ad Section
                  const Text(
                    'About the Ad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _aboutAdController,
                    decoration: const InputDecoration(
                      hintText: 'Provide details about your ad...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty
                        ? 'Please provide details about the ad'
                        : null,
                  ),
                  const SizedBox(height: 24.0),

                  // Special Instructions Section
                  const Text(
                    'Special Instructions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _specialInstructionsController,
                    decoration: const InputDecoration(
                      hintText: 'Any special requests or instructions...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24.0),

                  // Upload Ad Design Section
                  const Text(
                    'Ad Design Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: _pickAdDesign,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.grey[100],
                      ),
                      child: _adDesign == null
                          ? const Center(
                              child: Text(
                                'Tap to upload Ad Design',
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            )
                          : Image.file(
                              File(_adDesign!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Duration Section
                  const Text(
                    'Total Duration (in days)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      hintText: 'Specify duration in days',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty
                        ? 'Please specify the duration in days'
                        : null,
                  ),
                  const SizedBox(height: 24.0),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendBookingRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Send Booking Request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
