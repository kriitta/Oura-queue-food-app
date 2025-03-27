import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: AdminPanel(),
    );
  }
}

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> restaurantRequests = [
    {
      "name": "Fam Time",
      "location": "Siam Square Soi 4",
      "image": "assets/images/famtime.jpeg",
      "promotion": ["assets/images/promo-fam.jpg", "assets/images/promo-fam2.jpg", "assets/images/promo-fam3.jpg"],
      "phone" : "012-345-6789",
      "email" : "contact@famtime.com"
    },
    {
      "name": "Cheevit Cheeva",
      "location": "Emsphere Fl. 3",
      "image": "assets/images/cheevitcheeva.jpeg",
      "promotion": ["assets/images/promo-cheevit1.jpg", "assets/images/promo-cheevit2.jpg"],
      "phone" : "089-111-1111",
      "email" : "contact@cheevitcheeva.com"
    },
  ];

  List<Map<String, dynamic>> verifiedRestaurants = [];

  void approveRestaurant(int index) {
    setState(() {
      verifiedRestaurants.add(restaurantRequests[index]);
      restaurantRequests.removeAt(index);
    });
  }

  void denyRestaurant(int index) {
    setState(() {
      restaurantRequests.removeAt(index);
    });
  }

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(AwaitingVerificationPage(
      restaurantRequests: restaurantRequests,
      onApprove: approveRestaurant,
      onDeny: denyRestaurant,
    ));
    _pages.add(VerifiedPage(verifiedRestaurants: verifiedRestaurants));
    _pages.add(LogoutPage());
  }

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
        title: const Text("Oura", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hourglass_empty), label: "Awaiting"),
          BottomNavigationBarItem(icon: Icon(Icons.verified), label: "Verified"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}

/// ✅ **หน้า Awaiting Verification**
class AwaitingVerificationPage extends StatelessWidget {
  final List<Map<String, dynamic>> restaurantRequests;
  final Function(int) onApprove;
  final Function(int) onDeny;

  AwaitingVerificationPage({required this.restaurantRequests, required this.onApprove, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Awaiting Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: restaurantRequests.length,
              itemBuilder: (context, index) {
                final restaurant = restaurantRequests[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailPage(
                          restaurant: restaurant,
                          index: index,
                          onApprove: onApprove,
                          onDeny: onDeny,
                        ),
                      ),
                    );
                  },
                  child: RestaurantCard(
                    name: restaurant["name"],
                    location: restaurant["location"],
                    image: restaurant["image"],
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
/// ✅ **Card Widget for Displaying Restaurant Info**
class RestaurantCard extends StatelessWidget {
  final String name;
  final String location;
  final String image;

  RestaurantCard({required this.name, required this.location,  required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF8B2323))),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(image, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey[700])),
                    ],
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

/// ✅ **หน้าแสดงรายละเอียดของร้าน**
class RestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final int index;
  final Function(int) onApprove;
  final Function(int) onDeny;

  RestaurantDetailPage({required this.restaurant, required this.index, required this.onApprove, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 50, backgroundImage: AssetImage(restaurant["image"])),
            const SizedBox(height: 12),
            Text(restaurant["name"], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(restaurant["location"], style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const Divider(height: 30),
            const Text("Promotion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: restaurant["promotion"].length,
                itemBuilder: (context, promoIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Image.asset(restaurant["promotion"][promoIndex], width: 250),
                  );
                },
              ),
            ),
            const Divider(height: 30),
            const Text("Verify ?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    onDeny(index);
                    Navigator.pop(context);
                  },
                  child: const Text("Deny", style: TextStyle(color: Color(0xFF8B2323))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    onApprove(index);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2323)),
                  child: const Text("Approved", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VerifiedPage extends StatelessWidget {
  final List<Map<String, dynamic>> verifiedRestaurants;

  VerifiedPage({required this.verifiedRestaurants});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Verified Restaurants", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: verifiedRestaurants.isEmpty
                ? const Center(
                    child: Text("No Verified Restaurants Yet", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: verifiedRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = verifiedRestaurants[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerifiedRestaurantDetailPage(
                                restaurant: restaurant,
                                index: index,
                              ),
                            ),
                          );
                        },
                        child: RestaurantCard(
                          name: restaurant["name"],
                          location: restaurant["location"],
                          image: restaurant["image"],
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

/// ✅ **หน้าแสดงรายละเอียดของร้านที่ได้รับการอนุมัติ**
class VerifiedRestaurantDetailPage extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final int index;

  VerifiedRestaurantDetailPage({required this.restaurant, required this.index});

  void _showContactModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Contact Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("📞 Phone: ${restaurant["phone"] ?? "N/A"}"),
              const SizedBox(height: 8),
              Text("📧 Email: ${restaurant["email"] ?? "N/A"}"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 50, backgroundImage: AssetImage(restaurant["image"])),
            const SizedBox(height: 12),
            Text(restaurant["name"], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(restaurant["location"], style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const Divider(height: 30),
            const Text("Promotion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: restaurant["promotion"].length,
                itemBuilder: (context, promoIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Image.asset(restaurant["promotion"][promoIndex], width: 250),
                  );
                },
              ),
            ),
            const Divider(height: 30),
            const Text("Something went wrong?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // ลบแล้วกลับไปหน้า Verified
                  },
                  child: const Text("Delete", style: TextStyle(color: Color(0xFF8B2323))),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _showContactModal(context); // แสดง Contact Modal
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2323)),
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
class LogoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.exit_to_app, size: 100, color: Colors.red[700]), // ✅ ไอคอน Logout
          const SizedBox(height: 20),
          const Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "If you log out, you will need to sign in again to access the admin panel.",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  // ✅ ปิด Modal และยกเลิก Logout
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  side: const BorderSide(color: Color(0xFF8B2323)),
                ),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B2323), fontSize: 16)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // ✅ กลับไปหน้า Login หรือหน้าหลัก
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2323),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}