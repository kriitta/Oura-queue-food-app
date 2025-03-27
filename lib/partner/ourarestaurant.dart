import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_final/system/main.dart';
import '../system/firebase_options.dart';
import 'edit_restaurant_screen.dart';
import 'edit_promotion_screen.dart';
import 'manage_reservation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Queue',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? restaurantData;
  bool _isLoading = true;

  // สร้าง List ของหน้า (pages) ที่จะใช้ใน IndexedStack
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
    
    // Initialize pages with loading placeholders first
    _pages = [
      const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323))),
      const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323))),
      const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323))),
      const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323))),
    ];
  }

  Future<void> _loadRestaurantData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the active restaurant ID from settings
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('active_restaurant')
          .get();

      if (!settingsDoc.exists) {
        throw Exception('No active restaurant found');
      }

      Map<String, dynamic> settingsData = settingsDoc.data() as Map<String, dynamic>;
      String restaurantId = settingsData['restaurantId'];

      // Fetch restaurant data
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        throw Exception('Restaurant not found');
      }

      // Set restaurant data
      restaurantData = restaurantDoc.data() as Map<String, dynamic>;
      
      // Now initialize pages with the restaurant data
      _pages = [
        HomeScreen(restaurantData: restaurantData),
        ReservationScreen(restaurantData: restaurantData),
        RewardScreen(restaurantData: restaurantData),
        SettingScreen(restaurantData: restaurantData),
      ];
    } catch (e) {
      print('Error loading restaurant data: $e');
      // Handle error - maybe show an error screen or redirect back to login
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
          "Oura Restaurant",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323)))
        : IndexedStack(
            index: _currentIndex, // ใช้ currentIndex ในการเลือกหน้า
            children: _pages, // หน้าใน _pages
          ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex, // ใช้ _currentIndex เพื่อเปลี่ยนหน้า
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // เปลี่ยนหน้าเมื่อเลือก
          });
        },
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_front_rounded),
            label: 'Reservation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;

  const HomeScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tableQueues = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantQueues();
  }

  Future<void> _loadRestaurantQueues() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.restaurantData == null || widget.restaurantData!['restaurantId'] == null) {
        // Generate demo data if no restaurant data is available
        tableQueues = [
          {
            'type': 'Table type A : 1 - 2 persons',
            'queueNow': '#A097',
            'queueNext': '#A098',
            'seatNow': '2',
            'seatNext': '1',
          },
          {
            'type': 'Table type B : 3 - 6 persons',
            'queueNow': '#B032',
            'queueNext': '#B033',
            'seatNow': '3',
            'seatNext': '6',
          },
          {
            'type': 'Table type C : 7 - 12 persons',
            'queueNow': '#C027',
            'queueNext': '#C028',
            'seatNow': '9',
            'seatNext': '11',
          },
        ];
      } else {
        // Get restaurant ID
        String restaurantId = widget.restaurantData!['restaurantId'];
        
        // Fetch real queue data from Firestore
        QuerySnapshot queueSnapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('tables')
            .get();
            
        if (queueSnapshot.docs.isNotEmpty) {
          tableQueues = queueSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'type': data['type'] ?? 'Unknown table type',
              'queueNow': data['queueNow'] ?? '#---',
              'queueNext': data['queueNext'] ?? '#---',
              'seatNow': data['seatNow']?.toString() ?? '0',
              'seatNext': data['seatNext']?.toString() ?? '0',
            };
          }).toList();
        } else {
          // If no queue data exists yet, initialize with default values
          tableQueues = [
            {
              'type': 'Table type A : 1 - 2 persons',
              'queueNow': '#A001',
              'queueNext': '#A002',
              'seatNow': '0',
              'seatNext': '0',
            },
            {
              'type': 'Table type B : 3 - 6 persons',
              'queueNow': '#B001',
              'queueNext': '#B002',
              'seatNow': '0',
              'seatNext': '0',
            },
            {
              'type': 'Table type C : 7 - 12 persons',
              'queueNow': '#C001',
              'queueNext': '#C002',
              'seatNow': '0',
              'seatNext': '0',
            },
          ];
          
          // Create the initial table types in Firestore
          for (var table in tableQueues) {
            await FirebaseFirestore.instance
                .collection('restaurants')
                .doc(restaurantId)
                .collection('tables')
                .add(table);
          }
        }
      }
    } catch (e) {
      print('Error loading queue data: $e');
      // Fallback to demo data
      tableQueues = [
        {
          'type': 'Table type A : 1 - 2 persons',
          'queueNow': '#A097',
          'queueNext': '#A098',
          'seatNow': '2',
          'seatNext': '1',
        },
        {
          'type': 'Table type B : 3 - 6 persons',
          'queueNow': '#B032',
          'queueNext': '#B033',
          'seatNow': '3',
          'seatNext': '6',
        },
        {
          'type': 'Table type C : 7 - 12 persons',
          'queueNow': '#C027',
          'queueNext': '#C028',
          'seatNow': '9',
          'seatNext': '11',
        },
      ];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update queue after passing or advancing
  Future<void> _updateQueue(int index, bool isNext) async {
    try {
      // Get restaurant ID
      String? restaurantId = widget.restaurantData?['restaurantId'];
      if (restaurantId == null) return;
      
      // Get queue data
      var currentQueue = tableQueues[index];
      
      // Update the queue numbers
      Map<String, dynamic> updatedQueue = Map.from(currentQueue);
      
      if (isNext) {
        // Advance to next queue
        String currentQueueNum = currentQueue['queueNow'];
        String nextQueueNum = currentQueue['queueNext'];
        
        // Extract the letter prefix and number
        String prefix = currentQueueNum.substring(0, 2);
        int nextNumber = int.parse(nextQueueNum.substring(2)) + 1;
        
        // Update the queues
        updatedQueue['queueNow'] = nextQueueNum;
        updatedQueue['queueNext'] = '$prefix${nextNumber.toString().padLeft(3, '0')}';
        updatedQueue['seatNow'] = currentQueue['seatNext'];
        updatedQueue['seatNext'] = (1 + Random().nextInt(12)).toString(); // Random for demo
      } else {
        // Pass the current queue
        String nextQueueNum = currentQueue['queueNext'];
        
        // Extract the letter prefix and number
        String prefix = nextQueueNum.substring(0, 2);
        int currentNumber = int.parse(currentQueue['queueNow'].substring(2));
        int nextNumber = int.parse(nextQueueNum.substring(2)) + 1;
        
        // Update the queues
        updatedQueue['queueNow'] = nextQueueNum;
        updatedQueue['queueNext'] = '$prefix${nextNumber.toString().padLeft(3, '0')}';
        updatedQueue['seatNow'] = currentQueue['seatNext'];
        updatedQueue['seatNext'] = (1 + Random().nextInt(12)).toString(); // Random for demo
      }
      
      // Update in Firestore
      QuerySnapshot tableSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .where('type', isEqualTo: currentQueue['type'])
          .get();
          
      if (tableSnapshot.docs.isNotEmpty) {
        await tableSnapshot.docs.first.reference.update(updatedQueue);
      }
      
      // Update local state
      setState(() {
        tableQueues[index] = updatedQueue;
      });
      
    } catch (e) {
      print('Error updating queue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating queue: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2323)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Info Section
                if (widget.restaurantData != null) ...[
                  Row(
                    children: [
                      // Restaurant Image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          image: widget.restaurantData!['restaurantImage'] != null
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Decode(widget.restaurantData!['restaurantImage']),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        ),
                        child: widget.restaurantData!['restaurantImage'] == null
                          ? const Icon(Icons.restaurant, color: Colors.grey, size: 30)
                          : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurantData!['name'] ?? 'Your Restaurant',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${widget.restaurantData!['location'] ?? 'No location'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      'Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Table Queue Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: tableQueues.length,
                    itemBuilder: (context, index) {
                      final queue = tableQueues[index];
                      return buildTableCard(
                        index: index,
                        title: queue['type'],
                        queueNow: queue['queueNow'],
                        queueNext: queue['queueNext'],
                        seatNow: queue['seatNow'],
                        seatNext: queue['seatNext'],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget buildTableCard({
    required int index,
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
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                queueInfo(
                    title: 'Queue Now', queueNum: queueNow, seat: seatNow),
                queueInfo(
                    title: 'Next Queue', queueNum: queueNext, seat: seatNext),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                navigationButton(
                  icon: Icons.arrow_back, 
                  label: 'Pass Queue',
                  onPressed: () => _updateQueue(index, false),
                ),
                navigationButton(
                  icon: Icons.arrow_forward, 
                  label: 'Next Queue',
                  onPressed: () => _updateQueue(index, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget queueInfo(
      {required String title, required String queueNum, required String seat}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          queueNum,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('Seat: $seat'),
      ],
    );
  }

  Widget navigationButton({
    required IconData icon, 
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  
  const ReservationScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  List<Map<String, String>> reservations = [];
  List<Map<String, String>> upcomingReservations = [
    {'id': '#R025', 'seat': '2', 'time': '12:30', 'status': '-'},
    {'id': '#R026', 'seat': '4', 'time': '18:20', 'status': '-'},
    {'id': '#R027', 'seat': '4', 'time': '19:45', 'status': '-'},
    {'id': '#R028', 'seat': '6', 'time': '20:35', 'status': '-'},
    {'id': '#R029', 'seat': '6', 'time': '20:35', 'status': '-'},
    {'id': '#R030', 'seat': '6', 'time': '20:35', 'status': '-'},
  ];

  void markAsComplete(int index) {
    setState(() {
      // เปลี่ยนสถานะคิวที่เลือกจาก upcoming เป็น 'complete'
      upcomingReservations[index]['status'] = 'complete';

      // นำคิวที่กด complete ไปอยู่ใน reservation
      reservations.add(upcomingReservations[index]);

      // ถ้ามีคิวใน reservation มากกว่า 2 คิว ให้ลบคิวแรกสุดออก
      if (reservations.length > 2) {
        reservations.removeAt(0); // ลบคิวที่อยู่ในตำแหน่งแรก
      }

      // ลบคิวที่ถูกกด complete จาก upcomingReservations
      upcomingReservations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    
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
                const SizedBox(width: 10),
                const Column(
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
            const SizedBox(height: 16),

            const Text(
              'Reservation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Show reservations (only 2 reservations are displayed)
            if (reservations.isNotEmpty)
              ...reservations
                  .map((reservation) => buildReservationCard(
                      reservation, reservations.indexOf(reservation)))
                  .toList(),
            if (reservations.isEmpty)
              const Center(
                  child: Text("No reservations have been completed yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey))),
            const SizedBox(height: 20),

            if (upcomingReservations.isNotEmpty) ...[
              const Text(
                'Upcoming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: upcomingReservations.length,
                  itemBuilder: (context, index) {
                    return buildUpcomingCard(
                        upcomingReservations[index], index);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildReservationCard(Map<String, String> res, int index) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                    style: const TextStyle(
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
                ElevatedButton(
                  onPressed: res['status'] == 'complete'
                      ? null
                      : () {
                          setState(() {
                            res['status'] = 'complete';
                          });
                          markAsComplete(index);
                        },
                  child: Icon(
                    Icons.check,
                    color: res['status'] == 'complete'
                        ? Colors.green
                        : Colors.grey,
                    size: 20,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: res['status'] == 'complete'
                        ? Colors.green
                        : Colors.grey[300],
                    disabledForegroundColor: Colors.grey.withOpacity(0.38),
                    disabledBackgroundColor: Colors.grey
                        .withOpacity(0.12), // กำหนดสีปุ่มเมื่อไม่สามารถกดได้
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ),
                const Text(
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

  Widget buildUpcomingCard(Map<String, String> res, int index) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // ข้อมูลคิว
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res['id']!,
                    style: const TextStyle(
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
            // ส่วนปุ่ม Complete และ Delete
            Column(
              children: [
                // ปุ่ม Complete ที่ไม่สามารถกดได้ถ้าคิวอยู่ใน Reservation
                GestureDetector(
                  onTap: res['status'] == 'complete'
                      ? null // ไม่ให้กดเมื่อสถานะเป็น 'complete'
                      : () {
                          setState(() {
                            res['status'] = 'complete';
                          });
                          markAsComplete(index);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: res['status'] == 'complete'
                          ? Colors.green
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                    height: 10), // ระยะห่างระหว่างปุ่ม Complete และ Delete
                // ปุ่ม Delete ที่สามารถกดได้
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      // ลบคิวใน upcoming
                      upcomingReservations.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RewardScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  
  const RewardScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _RewardScreenState createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final TextEditingController _rewardNumberController = TextEditingController();
  String _reward = '';

  
void _submitReward() {
    String rewardId = _rewardNumberController.text;
    if (rewardId.isNotEmpty) {
      // ส่งไปยัง Backend หรือเก็บข้อมูล
      print("Reward ID: $rewardId"); // ตัวอย่างการแสดงข้อมูล
      // ส่งข้อมูลไปยัง Backend เช่น ผ่าน API หรือ Firebase
    } else {
      // แจ้งเตือนเมื่อกรอกข้อมูลไม่ครบ
      print("Please enter Reward ID.");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Reward Number:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // ช่องกรอกข้อมูล
            TextField(
              controller: _rewardNumberController,
              decoration: InputDecoration(
                hintText: 'Enter Reward Number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // ปุ่ม Submit
            ElevatedButton(
              onPressed: _submitReward,
              child: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2323), // สีพื้นหลัง
                foregroundColor: Colors.white, // สีข้อความในปุ่ม
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            // แสดงรางวัล
            if (_reward.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Reward Number: $_reward',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingScreen extends StatelessWidget {
  final Map<String, dynamic>? restaurantData;
  
  const SettingScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              // Restaurant Info Section (Optional)
              if (restaurantData != null) ...[
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: restaurantData!['restaurantImage'] != null
                      ? MemoryImage(base64Decode(restaurantData!['restaurantImage']))
                      : null,
                  child: restaurantData!['restaurantImage'] == null
                      ? const Icon(Icons.restaurant, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  restaurantData!['name'] ?? 'Your Restaurant',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  restaurantData!['location'] ?? 'No location',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
              ],
              
              buildSettingCard(
                context,
                icon: Icons.storefront,
                title: "Edit Restaurant Info",
                page: EditRestaurantScreen(restaurantData: restaurantData),
              ),
              const SizedBox(height: 20),
              buildSettingCard(
                context,
                icon: Icons.local_offer,
                title: "Edit Promotions",
                page: EditPromotionScreen(restaurantData: restaurantData),
              ),
              const SizedBox(height: 20),
              buildSettingCard(
                context,
                icon: Icons.schedule,
                title: "Manage Reservations",
                page: ManageReservationScreen(restaurantData: restaurantData),
              ),
              const SizedBox(height: 40),
              buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSettingCard(BuildContext context,
      {required IconData icon, required String title, required Widget page}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B2323)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        "Log out",
        style: TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B2323),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        minimumSize: const Size(double.infinity, 55),
      ),
    );
  }
}