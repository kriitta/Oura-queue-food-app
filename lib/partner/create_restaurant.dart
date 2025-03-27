import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import '../system/main.dart';
import '../partner/ourarestaurant.dart';


class CreateRestaurantPage extends StatefulWidget {
  const CreateRestaurantPage({super.key});

  @override
  _CreateRestaurantPageState createState() => _CreateRestaurantPageState();
}

class _CreateRestaurantPageState extends State<CreateRestaurantPage> {
  File? _restaurantImage;
  File? _promotionImage;
  bool _isLoading = false;
  String? _restaurantImageBase64;
  String? _promotionImageBase64;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = '';
  }

  Future<void> _pickImage(bool isPromotion) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        if (isPromotion) {
          _promotionImage = File(pickedFile.path);
          _convertImageToBase64(_promotionImage!, isPromotion: true);
        } else {
          _restaurantImage = File(pickedFile.path);
          _convertImageToBase64(_restaurantImage!, isPromotion: false);
        }
      });
    }
  }

  Future<void> _convertImageToBase64(File imageFile, {required bool isPromotion}) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      setState(() {
        if (isPromotion) {
          _promotionImageBase64 = base64Image;
        } else {
          _restaurantImageBase64 = base64Image;
        }
      });
    } catch (e) {
      print('Error converting image to base64: $e');
    }
  }

  Future<void> _createRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_restaurantImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload restaurant image')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get partner information
      DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(currentUser.uid)
          .get();
      
      if (!partnerDoc.exists) {
        throw Exception('Partner information not found');
      }

      // Create restaurant document
      DocumentReference restaurantRef = await FirebaseFirestore.instance.collection('restaurants').add({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'restaurantImage': _restaurantImageBase64,
        'promotionImage': _promotionImageBase64,
        'ownerId': currentUser.uid,
        'ownerName': partnerDoc.get('ownerName'),
        'isVerified': false,
        'isAvailable': false,
        'rating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'queue': 0,
      });
      
      // Update partner document with restaurant reference
      await FirebaseFirestore.instance.collection('partners').doc(currentUser.uid).update({
        'restaurantId': restaurantRef.id,
        'hasSubmittedRestaurant': true,
        'restaurantStatus': 'pending',
      });

      // Navigate to thank you page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating restaurant: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          "Oura Partner",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create Restaurant",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Restaurant Image (Circle in center)
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _pickImage(false),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _restaurantImage != null
                                    ? FileImage(_restaurantImage!)
                                    : null,
                                child: _restaurantImage == null
                                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[700])
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => _pickImage(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B2323),
                                side: const BorderSide(color: Color(0xFF8B2323)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: const Text("Upload Restaurant Image"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Restaurant Name Field
                      _buildLabel("Restaurant Name *"),
                      _buildTextField(
                        context,
                        controller: _nameController,
                        hint: "Enter restaurant name",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Restaurant name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      _buildLabel("Location *"),
                      _buildTextField(
                        context,
                        controller: _locationController,
                        hint: "Enter location",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      _buildLabel("Description"),
                      _buildTextField(
                        context,
                        controller: _descriptionController,
                        hint: "Tell us about your restaurant (optional)",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Promotion Image
                      const Text(
                        "Promotion Image",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Promotion Image Container
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B2323), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _promotionImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_promotionImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Upload an image for promotion (optional)",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () => _pickImage(true),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF8B2323),
                                      side: const BorderSide(color: Color(0xFF8B2323)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    child: const Text("Upload Image"),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 32),

                      // Create Restaurant Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createRestaurant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B2323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Create Restaurant",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B2323), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF8B2323).withOpacity(0.8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B2323), width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ThankYouPage extends StatefulWidget {
  const ThankYouPage({super.key});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _restaurantData;
  String _verificationStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get partner information
      DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(currentUser.uid)
          .get();
      
      if (!partnerDoc.exists) {
        throw Exception('Partner information not found');
      }

      Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
      
      // Check if partner has a restaurant
      if (partnerData.containsKey('restaurantId') && partnerData['restaurantId'] != null) {
        // Load restaurant data
        DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(partnerData['restaurantId'])
            .get();
        
        if (restaurantDoc.exists) {
          _restaurantData = restaurantDoc.data() as Map<String, dynamic>;
          // Make sure restaurantId is included in the data
          _restaurantData!['restaurantId'] = restaurantDoc.id;
          _verificationStatus = _restaurantData!['isVerified'] ? 'verified' : 'pending';
        }
      }
    } catch (e) {
      print('Error loading restaurant data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to Restaurant Management Interface
  void _navigateToRestaurantInterface() async {
    try {
      // Get current user ID
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get partner document to get restaurantId
      DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(currentUser.uid)
          .get();

      if (!partnerDoc.exists) {
        throw Exception('Partner information not found');
      }
      
      Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
      String restaurantId = partnerData['restaurantId'];
      
      // Set this restaurant as the active restaurant in a global settings collection
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('active_restaurant')
          .set({
            'restaurantId': restaurantId,
            'restaurantName': _restaurantData?['name'] ?? 'Restaurant',
            'lastUpdated': FieldValue.serverTimestamp()
          });
      
      // Navigate to the MainPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting restaurant interface: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainApp()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          "Oura Partner",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323)))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Restaurant Status",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // Restaurant Image
                    if (_restaurantData != null && _restaurantData!.containsKey('restaurantImage'))
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _restaurantData!['restaurantImage'] != null
                            ? MemoryImage(base64Decode(_restaurantData!['restaurantImage']))
                            : null,
                        child: _restaurantData!['restaurantImage'] == null
                            ? Icon(Icons.restaurant, size: 40, color: Colors.grey[700])
                            : null,
                      )
                    else
                      Image.asset('assets/images/oura-character.png', height: 120),
                      
                    const SizedBox(height: 20),
                    
                    // Restaurant Name
                    if (_restaurantData != null)
                      Text(
                        _restaurantData!['name'] ?? 'Your Restaurant',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                    const SizedBox(height: 10),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _verificationStatus == 'verified' 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _verificationStatus == 'verified' 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _verificationStatus == 'verified' 
                                ? Icons.verified 
                                : Icons.pending,
                            color: _verificationStatus == 'verified' 
                                ? Colors.green 
                                : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _verificationStatus == 'verified' 
                                ? 'Verified' 
                                : 'Pending Verification',
                            style: TextStyle(
                              color: _verificationStatus == 'verified' 
                                  ? Colors.green 
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Status Message
                    Text(
                      _verificationStatus == 'verified'
                          ? "Your restaurant has been verified! You can now start accepting reservations."
                          : "Please wait while the admin verifies your restaurant.\nKeep your notifications on, and we'll notify you once the verification is complete.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // NEW: Start Button for verified restaurants
                    if (_verificationStatus == 'verified')
                      ElevatedButton(
                        onPressed: _navigateToRestaurantInterface,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu, color: Colors.white),
                            SizedBox(width: 8),
                            Text("Start Restaurant",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 15),
                    
                    // Logout Button
                    ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2323),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}