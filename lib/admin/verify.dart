import 'package:flutter/material.dart';
import 'package:project_final/partner/edit_restaurant_screen.dart';
import '../system/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './verification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const AdminPanel(),
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  // Update this list to use VerifiedRestaurantsView instead of VerifiedPage
  final List<Widget> _pages = [
    const AwaitingVerificationView(),
    const VerifiedRestaurantsView(), // Changed from VerifiedPage
    const LogoutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          "Oura Admin",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.left,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty),
            label: "Awaiting",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: "Verified",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),
    );
  }
}

/// ✅ **หน้า 1: Awaiting Verification (Title ชิดซ้าย)**
class AwaitingVerificationPage extends StatelessWidget {
  const AwaitingVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0), // ✅ ให้ขอบห่างจากขอบจอ
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ ทำให้ข้อความชิดซ้าย
        children: [
          Text(
            "Awaiting Verification",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Spacer(), // ✅ ดันให้ข้อความอยู่ตรงกลาง
          Center(
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("Empty :(", style: TextStyle(fontSize: 20, color: Colors.grey)),
                SizedBox(height: 5),
                Text("No restaurant waiting for verify", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Spacer(), // ✅ ดันให้ห่างขอบล่าง
        ],
      ),
    );
  }
}

/// ✅ **หน้า 2: Verified**
class VerifiedPage extends StatelessWidget {
  const VerifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Verified Restaurants",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Icon(Icons.verified, size: 60, color: Colors.green),
          SizedBox(height: 10),
          Text("No verified restaurants yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// ✅ **หน้า 3: Logout**
class LogoutPage extends StatelessWidget {

  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Are you sure you want to logout?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
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
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2323),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class VerifyRestaurantsPage extends StatefulWidget {
  const VerifyRestaurantsPage({super.key});

  @override
  _VerifyRestaurantsPageState createState() => _VerifyRestaurantsPageState();
}

class _VerifyRestaurantsPageState extends State<VerifyRestaurantsPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Oura Header
            Container(
              color: const Color(0xFF8B2323),
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Oura',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Switch between views based on selected index
            if (_selectedIndex == 0) const AwaitingVerificationView(),
            if (_selectedIndex == 1) const VerifiedRestaurantsView(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty),
            label: 'Awaiting',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'Verified',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

class LogoutView extends StatelessWidget {
  const LogoutView({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      // Implement logout logic
      // For example:
      // await FirebaseAuth.instance.signOut();
      
      // Navigate to login or main screen
      // Navigator.of(context).pushReplacement(...);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.exit_to_app, 
              size: 100, 
              color: Color(0xFF8B2323)
            ),
            const SizedBox(height: 20),
            const Text(
              "Are you sure you want to log out?",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "You will need to sign in again to access the admin panel.",
              style: TextStyle(
                fontSize: 16, 
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2323),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40, 
                  vertical: 12
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Log out",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AwaitingVerificationView extends StatelessWidget {
  const AwaitingVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Awaiting Verification Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Awaiting Verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),

          // Restaurant List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .where('isVerified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B2323)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No restaurants waiting for verification",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var restaurant = snapshot.data!.docs[index];
                    return _RestaurantVerificationCard(
                      restaurantData: restaurant.data() as Map<String, dynamic>,
                      restaurantId: restaurant.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedRestaurantsView extends StatefulWidget {
  const VerifiedRestaurantsView({super.key});

  @override
  _VerifiedRestaurantsViewState createState() => _VerifiedRestaurantsViewState();
}

class _VerifiedRestaurantsViewState extends State<VerifiedRestaurantsView> {
  bool _isUpdatingCoordinates = false;

  // เพิ่มฟังก์ชันนี้
  Future<void> _updateAllCoordinates() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการอัปเดตพิกัด"),
        content: const Text("คุณต้องการอัปเดตพิกัดของร้านอาหารทั้งหมดหรือไม่? กระบวนการนี้อาจใช้เวลานาน"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("อัปเดต", style: TextStyle(color: Color(0xFF8B2323))),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isUpdatingCoordinates = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังอัปเดตพิกัดร้านอาหาร โปรดรอสักครู่...')),
      );
      
      try {
        await LocationService.batchUpdateRestaurantCoordinates();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตพิกัดร้านอาหารเรียบร้อยแล้ว')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      } finally {
        setState(() {
          _isUpdatingCoordinates = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Successfully Verified Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isUpdatingCoordinates ? null : _updateAllCoordinates,
              icon: _isUpdatingCoordinates 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.location_on),
              label: const Text('อัปเดตพิกัดร้านอาหารทั้งหมด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2323),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Restaurant List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B2323)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No verified restaurants yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var restaurant = snapshot.data!.docs[index];
                    var restaurantData = restaurant.data() as Map<String, dynamic>;
                    
                    // Get queue count from restaurantData or randomize for demo
                    int queueCount = restaurantData['queueCount'] ?? 
                                     (index * 7 + 5); // Generate random number for demo
                    
                    return VerifiedRestaurantCard(
                      restaurantData: restaurantData,
                      restaurantId: restaurant.id,
                      queueCount: queueCount,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VerifiedRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final String restaurantId;
  final int queueCount;

  const VerifiedRestaurantCard({
    required this.restaurantData,
    required this.restaurantId,
    required this.queueCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to restaurant details when card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              restaurantData: restaurantData,
              restaurantId: restaurantId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B2323), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Restaurant Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: restaurantData['restaurantImage'] != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(restaurantData['restaurantImage'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: restaurantData['restaurantImage'] == null
                    ? const Icon(Icons.restaurant, color: Colors.grey, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Restaurant Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurantData['name'] ?? 'Unnamed Restaurant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurantData['location'] ?? 'No location',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Description with icon (replacing Queue)
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurantData['description'] ?? 'No description',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _RestaurantVerificationCard extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final String restaurantId;
  final bool isVerified;

  const _RestaurantVerificationCard({
    required this.restaurantData,
    required this.restaurantId,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get queue count from restaurantData or set default value
    int queueCount = restaurantData['queueCount'] ?? 0;
    
    // If card is in verified section but has no queue, generate a random number for demo
    if (isVerified && queueCount == 0) {
      // Generate a semi-random queue number based on restaurant name length for demo
      queueCount = (restaurantData['name']?.length ?? 1) * 7 + 5;
    }
    
    return GestureDetector(
      onTap: () {
        _showRestaurantDetails(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B2323), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Restaurant Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: restaurantData['restaurantImage'] != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(restaurantData['restaurantImage'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: restaurantData['restaurantImage'] == null
                    ? const Icon(Icons.restaurant, color: Colors.grey, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Restaurant Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name
                    Text(
                      restaurantData['name'] ?? 'Unnamed Restaurant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurantData['location'] ?? 'No location',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    // Only show queue for verified restaurants
                    if (isVerified) ...[
                      const SizedBox(height: 8),
                      // Queue with icon
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Queue : $queueCount",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Only show description for non-verified restaurants
                    if (!isVerified) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.info,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              restaurantData['description'] ?? 'No description',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestaurantDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RestaurantDetailsSheet(
        restaurantData: restaurantData,
        restaurantId: restaurantId,
        isVerified: isVerified,
      ),
    );
  }
}

class RestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final String restaurantId;

  const RestaurantDetailPage({
    required this.restaurantData,
    required this.restaurantId,
  });

  // Improved contact method that fetches owner information
  void _showContactModal(BuildContext context) async {
    // Show loading dialog while fetching data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B2323)),
      ),
    );

    try {
      // Initialize contact information variables
      String phone = 'N/A';
      String email = 'N/A';
      
      // Try to get contact from restaurant data first
      if (restaurantData["phone"] != null && restaurantData["phone"].toString().isNotEmpty) {
        phone = restaurantData["phone"];
      }
      
      if (restaurantData["email"] != null && restaurantData["email"].toString().isNotEmpty) {
        email = restaurantData["email"];
      }
      
      // If we have an ownerId, try to get contact info from the partners collection
      if (restaurantData['ownerId'] != null) {
        try {
          DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
              .collection('partners')
              .doc(restaurantData['ownerId'])
              .get();
          
          if (ownerDoc.exists) {
            Map<String, dynamic> ownerData = ownerDoc.data() as Map<String, dynamic>;
            
            // Update phone if available in owner data
            if (ownerData['phone'] != null && ownerData['phone'].toString().isNotEmpty) {
              phone = ownerData['phone'];
            }
            
            // Update email if available in owner data
            if (ownerData['email'] != null && ownerData['email'].toString().isNotEmpty) {
              email = ownerData['email'];
            }
          }
        } catch (e) {
          print('Error fetching owner data: $e');
        }
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show contact information dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Contact Information"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("📞 Phone: $phone"),
                const SizedBox(height: 8),
                Text("📧 Email: $email"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog and show error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contact information: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text("Restaurant Details", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Restaurant Logo/Image
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: restaurantData['restaurantImage'] != null
                  ? MemoryImage(base64Decode(restaurantData['restaurantImage']))
                  : null,
              child: restaurantData['restaurantImage'] == null
                  ? const Icon(Icons.restaurant, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),
            
            // Restaurant Name
            Text(
              restaurantData["name"] ?? "Unnamed Restaurant", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            
            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  restaurantData["location"] ?? "No location", 
                  style: TextStyle(color: Colors.grey[700])
                ),
              ],
            ),
            
            // Description (replaced Queue)
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                    restaurantData["description"] ?? "No description", 
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                
              ],
            ),
            
            const Divider(height: 30),
            const Text("Promotion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Promotion Image
            Expanded(
              child: restaurantData['promotionImage'] != null
                ? Image.memory(
                    base64Decode(restaurantData['promotionImage']),
                    fit: BoxFit.contain,
                  )
                : const Center(
                    child: Text("No promotions available", 
                      style: TextStyle(color: Colors.grey)
                    ),
                  ),
            ),
            
            const Divider(height: 30),
            const Text("Restaurant Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    // Show confirmation dialog
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Removal"),
                        content: const Text("Are you sure you want to remove this restaurant from verified list?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Remove", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      try {
                        // Update restaurant verification status
                        await FirebaseFirestore.instance
                            .collection('restaurants')
                            .doc(restaurantId)
                            .update({
                          'isVerified': false,
                        });
                        
                        Navigator.pop(context); // Return to verified list
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restaurant removed from verified list'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B2323)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Remove", style: TextStyle(color: Color(0xFF8B2323))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _showContactModal(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2323),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Contact", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class _RestaurantDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final String restaurantId;
  final bool isVerified;

  const _RestaurantDetailsSheet({
    required this.restaurantData,
    required this.restaurantId,
    this.isVerified = false,
  });

  Future<void> _verifyRestaurant(BuildContext context, bool isApproved) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังดำเนินการ...'),
          duration: Duration(seconds: 1),
        ),
      );

      if (isApproved) {
        // APPROVE RESTAURANT - Set isVerified to true
        print('Approving restaurant: $restaurantId');
        
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .update({
          'isVerified': true,
          'isAvailable': true,
          'queueCount': 0,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        
        print('Restaurant verified successfully');
        
        // Update owner status if available
        if (restaurantData['ownerId'] != null) {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(restaurantData['ownerId'])
              .update({
            'restaurantStatus': 'verified',
          });
          print('Owner status updated');
        }
        
        // Close bottom sheet and show success message
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อนุมัติร้านอาหารสำเร็จ'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // DENY RESTAURANT - Delete from database
        print('Denying restaurant: $restaurantId');
        
        // Delete restaurant completely
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .delete();
        
        print('Restaurant deleted from database');
        
        // Update owner status if available
        if (restaurantData['ownerId'] != null) {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(restaurantData['ownerId'])
              .update({
            'restaurantStatus': 'denied',
            'restaurantId': null,
            'hasSubmittedRestaurant': false,
          });
          print('Owner status updated after denial');
        }
        
        // Close bottom sheet and show denial message
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปฏิเสธร้านอาหารเรียบร้อย'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error handling
      print('Error in verification process: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Make sure bottom sheet is closed
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
  
  // Improved contact method that fetches owner information
  void _showContactModal(BuildContext context) async {
    // Show loading dialog while fetching data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B2323)),
      ),
    );

    try {
      // Initialize contact information variables
      String phone = 'N/A';
      String email = 'N/A';
      
      // Try to get contact from restaurant data first
      if (restaurantData["phone"] != null && restaurantData["phone"].toString().isNotEmpty) {
        phone = restaurantData["phone"];
      }
      
      if (restaurantData["email"] != null && restaurantData["email"].toString().isNotEmpty) {
        email = restaurantData["email"];
      } else if (restaurantData["ownerEmail"] != null && restaurantData["ownerEmail"].toString().isNotEmpty) {
        email = restaurantData["ownerEmail"];
      }
      
      // If we have an ownerId, try to get contact info from the partners collection
      if (restaurantData['ownerId'] != null) {
        try {
          DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
              .collection('partners')
              .doc(restaurantData['ownerId'])
              .get();
          
          if (ownerDoc.exists) {
            Map<String, dynamic> ownerData = ownerDoc.data() as Map<String, dynamic>;
            
            // Update phone if available in owner data
            if (ownerData['phone'] != null && ownerData['phone'].toString().isNotEmpty) {
              phone = ownerData['phone'];
            }
            
            // Update email if available in owner data
            if (ownerData['email'] != null && ownerData['email'].toString().isNotEmpty) {
              email = ownerData['email'];
            }
          }
        } catch (e) {
          print('Error fetching owner data: $e');
        }
      }
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show contact information dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Contact Information"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("📞 Phone: $phone"),
                const SizedBox(height: 8),
                Text("📧 Email: $email"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog and show error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contact information: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Back Button and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF8B2323)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isVerified ? 'Verified Restaurant' : 'Verify?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B2323),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Restaurant Logo
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: restaurantData['restaurantImage'] != null
                      ? MemoryImage(base64Decode(restaurantData['restaurantImage']))
                      : null,
                  child: restaurantData['restaurantImage'] == null
                      ? Icon(Icons.restaurant, size: 60, color: Colors.grey[700])
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Restaurant Name
              Text(
                restaurantData['name'] ?? 'Unnamed Restaurant',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    restaurantData['location'] ?? 'No location provided',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              // Description (always show for both verified and non-verified)
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                restaurantData['description'] ?? 'No description provided',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Promotion Section
              const Text(
                'Promotion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Promotion Image
              if (restaurantData['promotionImage'] != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(restaurantData['promotionImage'])),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No promotion image available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 30),

              // Buttons Section
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => isVerified 
                          ? _verifyRestaurant(context, false)  // Remove from verified
                          : _verifyRestaurant(context, false), // Deny approval
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF8B2323), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isVerified ? 'Remove' : 'Deny',
                        style: const TextStyle(
                          color: Color(0xFF8B2323),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => isVerified
                          ? _showContactModal(context)       // Show contact info
                          : _verifyRestaurant(context, true), // Approve restaurant
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2323),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isVerified ? 'Contact' : 'Approved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}