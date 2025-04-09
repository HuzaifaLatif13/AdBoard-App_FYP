import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:adboard/modals/ad_modal.dart';

class EditAdScreen extends StatefulWidget {
  final AdModel ad;

  const EditAdScreen({
    Key? key,
    required this.ad,
  }) : super(key: key);

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _sizeController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late bool _isPublished;
  late List<String> _imageUrls;
  final List<String> categories = ['Billboards', 'Transit', 'In-Store'];
  String? selectedCategory;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with ad details
    _titleController = TextEditingController(text: widget.ad.title);
    _priceController = TextEditingController(text: widget.ad.price);
    _sizeController = TextEditingController(text: widget.ad.size);
    _locationController = TextEditingController(text: widget.ad.location);
    _descriptionController = TextEditingController(text: widget.ad.description);

    // Initialize _imageUrls with the ad's image URLs
    _imageUrls = widget.ad.imageUrls.isNotEmpty
        ? List.from(widget.ad.imageUrls)
        : []; // Ensure it's always a valid list

    // Initialize _isPublished
    _isPublished = widget.ad.availability;

    // Initialize selectedCategory
    selectedCategory = widget.ad.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageUrls.add(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Upload new images to Firebase Storage if necessary
      List<String> updatedImageUrls = List.from(_imageUrls);

      for (String imageUrl in _imageUrls) {
        if (!imageUrl.startsWith("https://")) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageRef =
              FirebaseStorage.instance.ref().child('ads/$fileName');
          UploadTask uploadTask = storageRef.putFile(File(imageUrl));
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
          String uploadedUrl = await taskSnapshot.ref.getDownloadURL();
          updatedImageUrls.add(uploadedUrl);
        }
      }

      // Get reference to the ad document in Firestore
      DocumentReference adRef = FirebaseFirestore.instance
          .collection('ads')
          .doc(FirebaseAuth.instance.currentUser?.uid) // The user's document
          .collection('userPosts') // The user's posts subcollection
          .doc(widget.ad.id); // The specific ad document

      // Update the document
      await adRef.update({
        'title': _titleController.text,
        'price': _priceController.text,
        'size': _sizeController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'availability': _isPublished, // Set availability based on publish state
        'category': selectedCategory,
        'imageUrls': updatedImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPublished
              ? 'Ad changes saved successfully!'
              : 'Ad unpublished successfully! Moved to Completed tab.'),
        ),
      );

      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteAd() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get reference to the ad document in Firestore
      DocumentReference adRef = FirebaseFirestore.instance
          .collection('ads')
          .doc(FirebaseAuth.instance.currentUser?.uid) // The user's document
          .collection('userPosts') // The user's posts subcollection
          .doc(widget.ad.id); // The specific ad document

      // Retrieve the ad document to get image URLs
      final adDoc = await adRef.get();

      if (adDoc.exists) {
        final data = adDoc.data() as Map<String, dynamic>;
        final List<String> imageUrls = List<String>.from(data['imageUrls']);

        // Delete images from Firebase Storage
        for (String imageUrl in imageUrls) {
          try {
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          } catch (e) {
            print('Failed to delete image from storage: $e');
          }
        }

        // Delete the Firestore document
        await adRef.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ad and associated images deleted successfully!')),
        );

        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ad: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Ad',
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
                  const Text(
                    'Ad Images',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageUrls.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == _imageUrls.length) {
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Image.network(
                              _imageUrls[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageUrls.removeAt(index);
                                  });
                                },
                                child: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ad Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory ?? widget.ad.category,
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a price' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sizeController,
                    decoration: const InputDecoration(
                      labelText: 'Size',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the size' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the location' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(_isPublished ? "Publish" : "Unpublish"),
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() {
                        _isPublished = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _deleteAd,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
