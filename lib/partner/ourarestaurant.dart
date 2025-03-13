import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_final/partner/bottom_nav.dart';
import '../firebase_options.dart';
import 'edit_restaurant_screen.dart';
import 'edit_promotion_screen.dart';
import 'manage_reservation_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Queue',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Oura',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: Image.asset(
                        'assets/images/famtime.jpeg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Fam Time',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('📍 Siam Square Soi 4',
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        queueInfo(
                            title: 'Queue Now', queueNum: '#Q097', seat: '2'),
                        queueInfo(
                            title: 'Next Queue', queueNum: '#Q098', seat: '4'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        queueInfo(
                            title: 'Latest Queue',
                            queueNum: '#Q120',
                            seat: '5'),
                        queueInfo(
                            title: 'Remaining', queueNum: '23', seat: 'Queue'),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                          ),
                          child: Icon(Icons.arrow_back),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                          ),
                          child: Icon(Icons.arrow_forward),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }

  // Widget สำหรับข้อมูล Queue
  Widget queueInfo(
      {required String title, required String queueNum, required String seat}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          queueNum,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('Seat: $seat'),
      ],
    );
  }
}

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
// เริ่มต้นที่หน้า Reservation

  List<Map<String, String>> reservations = [
    {'id': '#R025', 'seat': '2', 'time': '17:30', 'status': 'complete'},
    {'id': '#R026', 'seat': '4', 'time': '18:20', 'status': '-'},
    {'id': '#R027', 'seat': '4', 'time': '19:45', 'status': '-'},
  ];

  void markAsComplete(int index) {
    setState(() {
      reservations[index]['status'] = 'complete';
    });
  }


  @override
  Widget build(BuildContext context) {
    Map<String, String>? latestReservation;
    List<Map<String, String>> upcomingReservations = [];

    for (var res in reservations) {
      if (latestReservation == null || res['status'] == 'complete') {
        latestReservation = res;
      } else {
        upcomingReservations.add(res);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      appBar: AppBar(
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ
        title: Align(
          alignment: Alignment.centerLeft, // ชิดซ้าย
          child: Text(
            'Oura',
            style: TextStyle(
              color: Colors.white, // สีขาว
              fontSize: 22, // ขนาดตัวอักษร
              fontWeight: FontWeight.bold, // ตัวหนา
            ),
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // โลโก้ร้าน & ชื่อร้าน
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40.0),
                  child: Image.asset(
                    'assets/images/famtime.jpeg',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fam Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text('📍 Siam Square Soi 4',
                        style: TextStyle(color: Colors.black)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // คิวล่าสุด
            if (latestReservation != null) ...[
              Text(
                'Reservation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              buildReservationCard(latestReservation!, 0),
            ],
            SizedBox(height: 20),

            // Upcoming
            if (upcomingReservations.isNotEmpty) ...[
              Text(
                'Upcoming ..',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: upcomingReservations.length,
                  itemBuilder: (context, index) {
                    return buildReservationCard(
                        upcomingReservations[index], index + 1);
                  },
                ),
              ),
            ],

            // ปุ่ม Next
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(16),
                  backgroundColor: Color(0xFF8B2323),
                ),
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),


    );
  }

  // **สร้างการ์ดคูปอง**
  Widget buildReservationCard(Map<String, String> res, int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // **ขอบซ้ายสีแดง**
              Container(
                width: 8,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF8B2323),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
              ),
              // **รายละเอียดคิว**
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res['id']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Seat : ${res['seat']}"),
                      Text("Booked Time : ${res['time']}"),
                      Row(
                        children: [
                          Text("Status : ${res['status']}"),
                          SizedBox(width: 5),
                          Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // **ปุ่มติ๊กถูก**
              GestureDetector(
                onTap: () => markAsComplete(index),
                child: Container(
                  width: 60,
                  height: 100,
                  child: CustomPaint(
                    painter: DashedBorderPainter(),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: res['status'] == 'complete'
                            ? Colors.green
                            : Colors.grey,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// **สร้างเส้นประ**
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 5;
    double startY = 10;

    while (startY < size.height - 10) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => false;
}

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Oura',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSettingButton(context, "แก้ไขข้อมูลร้าน", EditRestaurantScreen()),
            SizedBox(height: 20),
            buildSettingButton(context, "แก้ไข promotion", EditPromotionScreen()),
            SizedBox(height: 20),
            buildSettingButton(context, "จัดการเวลาจองล่วงหน้า", ManageReservationScreen()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }

  Widget buildSettingButton(BuildContext context, String title, Widget page) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8B2323), // สีแดงเข้ม
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // ขอบโค้ง
        ),
        minimumSize: Size(double.infinity, 50), // ปรับขนาดปุ่ม
      ),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
