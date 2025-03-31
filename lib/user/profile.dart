import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../system/main.dart';

import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_userData == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userData: _userData!),
      ),
    );
    
    if (result == true) {
      _loadUserData();
    }
  }

  Future<Map<String, dynamic>> _loadActivityStats() async {
  Map<String, dynamic> stats = {
    'reservationCount': '0',
    'coins': '0',
    
  };
  
  try {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return stats;
    
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
        
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      if (userData.containsKey('coins')) {
        stats['coins'] = userData['coins'].toString();
      } else {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({'coins': 10});
        stats['coins'] = '10';
      }
    }
    
    QuerySnapshot reservationsSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .get();
    
    stats['reservationCount'] = reservationsSnapshot.docs.length.toString();
        
    
  } catch (e) {
    print('Error loading activity stats: $e');
  }
  
  return stats;
}

  Future<void> _signOut() async {
  try {
    await _auth.signOut();
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainApp()),
      (Route<dynamic> route) => false,  
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error signing out: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323)))
        : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Avatar
            GestureDetector(
              onTap: _navigateToEditProfile,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _userData?['profileImage'] != null && (_userData!['profileImage'] as String).isNotEmpty 
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFECDFDF),
                          backgroundImage: MemoryImage(base64Decode(_userData!['profileImage'])),
                          onBackgroundImageError: (_, __) {
                          },
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFECDFDF),
                          child: Text(
                            _getUserInitials(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B2323),
                            ),
                          ),
                        ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2323),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            // User Name
            Text(
              _userData?['name'] ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            
            // User Email
            Text(
              _userData?['email'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            
            // Profile Info Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(Icons.phone, 'Phone Number', _userData?['phone'] ?? 'Not provided'),
                    const SizedBox(height: 15),
                    _buildInfoRow(Icons.cake, 'Member Since', _formatDate(_userData?['createdAt'])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            FutureBuilder<Map<String, dynamic>>(
            future: _loadActivityStats(),
            builder: (context, snapshot) {
              String reservations = '0';
              String coins = '0';
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B2323),
                              strokeWidth: 2,
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (snapshot.hasData) {
                reservations = snapshot.data!['reservationCount'] ?? '0';
                coins = snapshot.data!['coins'] ?? '0';
              }
              
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildStatsRow('Total Reservations', reservations),
                      const SizedBox(height: 15),
                      _buildStatsRow('Reward Points', coins),
                      
                    ],
                  ),
                ),
              );
            },
          ),
            const SizedBox(height: 40),
            
            OutlinedButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit, color: Color(0xFF8B2323)),
              label: const Text(
                'Edit Profile',
                style: TextStyle(color: Color(0xFF8B2323)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8B2323)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2323),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B2323), size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B2323),
          ),
        ),
      ],
    );
  }

  String _getUserInitials() {
    String name = _userData?['name'] ?? 'U';
    if (name.isEmpty) return 'U';
    
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else {
      return name[0];
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not available';
    
    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return 'Not available';
    } catch (e) {
      return 'Not available';
    }
  }
}