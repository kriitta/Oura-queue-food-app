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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Oura',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  'Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            buildTableCard(
              title: 'Table type A : 1 - 2 persons',
              queueNow: '#A097',
              queueNext: '#A098',
              seatNow: '2',
              seatNext: '1',
            ),
            buildTableCard(
              title: 'Table type B : 3 - 6 persons',
              queueNow: '#B032',
              queueNext: '#B033',
              seatNow: '3',
              seatNext: '6',
            ),
            buildTableCard(
              title: 'Table type C : 7 - 12 persons',
              queueNow: '#C027',
              queueNext: '#C028',
              seatNow: '9',
              seatNext: '11',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }

  Widget buildTableCard({
    required String title,
    required String queueNow,
    required String queueNext,
    required String seatNow,
    required String seatNext,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white, // ตั้งค่าสีพื้นหลังของ Card ให้เป็นสีขาว
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                queueInfo(title: 'Queue Now', queueNum: queueNow, seat: seatNow),
                queueInfo(title: 'Next Queue', queueNum: queueNext, seat: seatNext),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                navigationButton(Icons.arrow_back, 'Pass Queue'),
                navigationButton(Icons.arrow_forward, 'Next Queue'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget queueInfo({required String title, required String queueNum, required String seat}) {
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

  Widget navigationButton(IconData icon, String label) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(16),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Oura',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Text(
              'Reservation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (latestReservation != null) buildReservationCard(latestReservation!, 0),
            SizedBox(height: 20),

            if (upcomingReservations.isNotEmpty) ...[
              Text(
                'Upcoming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: upcomingReservations.length,
                  itemBuilder: (context, index) {
                    return buildReservationCard(upcomingReservations[index], index + 1);
                  },
                ),
              ),
            ],

            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                      backgroundColor: Color(0xFF8B2323),
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Next',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }

  Widget buildReservationCard(Map<String, String> res, int index) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
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
                  Text("Status : ${res['status']}"),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => markAsComplete(index),
                  child: Icon(
                    Icons.check,
                    color: res['status'] == 'complete' ? Colors.green : Colors.grey,
                    size: 30,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Complete',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Oura',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              buildSettingCard(
                context,
                icon: Icons.storefront,
                title: "Edit Restaurant Info",
                page: EditRestaurantScreen(),
              ),
              SizedBox(height: 15),
              buildSettingCard(
                context,
                icon: Icons.local_offer,
                title: "Edit Promotions",
                page: EditPromotionScreen(),
              ),
              SizedBox(height: 15),
              buildSettingCard(
                context,
                icon: Icons.schedule,
                title: "Manage Reservations",
                page: ManageReservationScreen(),
              ),
              SizedBox(height: 30),
              buildLogoutButton(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }

  Widget buildSettingCard(BuildContext context, {required IconData icon, required String title, required Widget page}) {
    return Card(
      color: Colors.white, // เปลี่ยนพื้นหลังของ Card เป็นสีขาวให้ดู minimal
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF8B2323)),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.black54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }

  Widget buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Perform Logout Action
      },
      icon: Icon(Icons.logout, color: Colors.white),
      label: Text(
        "Log out",
        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8B2323),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }
}