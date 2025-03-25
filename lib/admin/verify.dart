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
  int _selectedIndex = 0; // หน้าที่เลือกใน BottomNavigationBar

  // รายการหน้า (Awaiting, Verified, Logout)
  final List<Widget> _pages = [
    AwaitingVerificationPage(),
    VerifiedPage(),
    LogoutPage(),
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
        backgroundColor: Color(0xFF8B2323),
        title: Text(
          "Oura",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.left, // ✅ ทำให้ชิดซ้าย
        ),
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex], // แสดงหน้าที่เลือก

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF8B2323), // สีแดงเข้มเมื่อเลือก
        unselectedItemColor: Colors.grey, // สีเทาสำหรับไอคอนไม่ได้เลือก
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty),
            label: "Awaiting",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: "Verified",
          ),
          BottomNavigationBarItem(
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // ✅ ให้ขอบห่างจากขอบจอ
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
  @override
  Widget build(BuildContext context) {
    return Center(
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Are you sure you want to logout?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // กลับไปหน้าหลัก
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B2323),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
