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
import '../system/notification_service.dart';

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

      Map<String, dynamic> settingsData =
          settingsDoc.data() as Map<String, dynamic>;
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
      restaurantData = {
        ...restaurantDoc.data() as Map<String, dynamic>,
        'restaurantId': restaurantDoc.id,
      };
      print('📡 loaded restaurantData = $restaurantData');

      // Now initialize pages with the restaurant data
      _pages = [
        HomeScreen(restaurantData: restaurantData),
        ReservationScreen(restaurantData: restaurantData),
        RewardScreen(restaurantData: restaurantData),
        SettingScreen(restaurantData: restaurantData),
      ];
      // print('📦 Sending restaurantData to HomeScreen: $restaurantData');
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
    final pages = restaurantData == null
        ? [
            const Center(child: CircularProgressIndicator()),
            const Center(child: CircularProgressIndicator()),
            const Center(child: CircularProgressIndicator()),
            const Center(child: CircularProgressIndicator()),
          ]
        : [
            HomeScreen(restaurantData: restaurantData),
            ReservationScreen(restaurantData: restaurantData),
            RewardScreen(restaurantData: restaurantData),
            SettingScreen(restaurantData: restaurantData),
          ];

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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)))
          : IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('📥 HomeScreen received restaurantData: ${widget.restaurantData}');
    if (!_initialized && widget.restaurantData != null) {
      fetchWalkInQueues();
      _initialized = true;
    }
  }

  Future<void> fetchWalkInQueues() async {
    setState(() {
      isLoading = true;
    });

    try {
      final restaurantId = widget.restaurantData?['restaurantId'];
      print('🍽 restaurantId from widget: $restaurantId'); // ✅ สำคัญ!
      if (restaurantId == null) {
        print('❗ restaurantId is null');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('queues')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isReservation', isEqualTo: false)
          .where('status', isEqualTo: 'waiting')
          .orderBy('timestamp')
          .get();

      print('📦 Walk-in queues found: ${snapshot.docs.length}');

      Map<String, List<QueryDocumentSnapshot>> groupedQueues = {
        '1-2 persons': [],
        '3-6 persons': [],
        '7-12 persons': [],
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tableType = data['tableType'];
        if (tableType == '1-2 persons') {
          groupedQueues['1-2 persons']!.add(doc);
        } else if (tableType == '3-6 persons') {
          groupedQueues['3-6 persons']!.add(doc);
        } else if (tableType == '7-12 persons') {
          groupedQueues['7-12 persons']!.add(doc);
        }

        print(
            '👀 queueCode: ${data['queueCode']} | tableType: ${data['tableType']}');
      }

      tableQueues = [
        {
          'type': 'Table type A : 1 - 2 persons',
          'queueNow': groupedQueues['1-2 persons']!.isNotEmpty
              ? groupedQueues['1-2 persons']![0]['queueCode']
              : '-',
          'queueNext': groupedQueues['1-2 persons']!.length > 1
              ? groupedQueues['1-2 persons']![1]['queueCode']
              : '-',
          'seatNow': groupedQueues['1-2 persons']!.isNotEmpty
              ? groupedQueues['1-2 persons']![0]['numberOfPersons'].toString()
              : '-',
          'seatNext': groupedQueues['1-2 persons']!.length > 1
              ? groupedQueues['1-2 persons']![1]['numberOfPersons'].toString()
              : '-',
        },
        {
          'type': 'Table type B : 3 - 6 persons',
          'queueNow': groupedQueues['3-6 persons']!.isNotEmpty
              ? groupedQueues['3-6 persons']![0]['queueCode']
              : '-',
          'queueNext': groupedQueues['3-6 persons']!.length > 1
              ? groupedQueues['3-6 persons']![1]['queueCode']
              : '-',
          'seatNow': groupedQueues['3-6 persons']!.isNotEmpty
              ? groupedQueues['3-6 persons']![0]['numberOfPersons'].toString()
              : '-',
          'seatNext': groupedQueues['3-6 persons']!.length > 1
              ? groupedQueues['3-6 persons']![1]['numberOfPersons'].toString()
              : '-',
        },
        {
          'type': 'Table type C : 7 - 12 persons',
          'queueNow': groupedQueues['7-12 persons']!.isNotEmpty
              ? groupedQueues['7-12 persons']![0]['queueCode']
              : '-',
          'queueNext': groupedQueues['7-12 persons']!.length > 1
              ? groupedQueues['7-12 persons']![1]['queueCode']
              : '-',
          'seatNow': groupedQueues['7-12 persons']!.isNotEmpty
              ? groupedQueues['7-12 persons']![0]['numberOfPersons'].toString()
              : '-',
          'seatNext': groupedQueues['7-12 persons']!.length > 1
              ? groupedQueues['7-12 persons']![1]['numberOfPersons'].toString()
              : '-',
        },
      ];
    } catch (e) {
      print("🔥 Error fetching queues: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading queue: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> _updateQueue(int index, bool isNext) async {
  try {
    String? restaurantId = widget.restaurantData?['restaurantId'];
    if (restaurantId == null) return;

    // Determine table type based on index
    String tableType = '';
    if (index == 0) tableType = '1-2 persons';
    if (index == 1) tableType = '3-6 persons';
    if (index == 2) tableType = '7-12 persons';

    // Check if there is a queue in the display table
    if (tableQueues[index]['queueNow'] == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่มีคิวที่รออยู่ในประเภทโต๊ะนี้")),
      );
      return; // Exit the function if there is no queue
    }

    // Save current and next queue information before updating
    final currentQueueCode = tableQueues[index]['queueNow'];
    final nextQueueCode = tableQueues[index]['queueNext'];
    final nextQueueSeat = tableQueues[index]['seatNext'];
    
    // Show processing message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("กำลัง${isNext ? 'ให้บริการเสร็จสิ้น' : 'ข้าม'}คิว $currentQueueCode"),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Update UI immediately
    setState(() {
      // Move next queue to current
      tableQueues[index]['queueNow'] = nextQueueCode;
      tableQueues[index]['seatNow'] = nextQueueSeat;
      
      // Set next queue to empty
      tableQueues[index]['queueNext'] = '-';
      tableQueues[index]['seatNext'] = '-';
    });
    
    // Find the queue to update
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isReservation', isEqualTo: false)
        .where('tableType', isEqualTo: tableType)
        .where('queueCode', isEqualTo: currentQueueCode)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot queueDoc = snapshot.docs[0];
      String userId = queueDoc['userId'] ?? '';
      String queueDocId = queueDoc.id; // เก็บ doc ID เพื่อใช้ในการลบข้อมูล
      
      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B2323)),
        ),
      );
      
      // อัปเดตสถานะของคิว
      await FirebaseFirestore.instance
          .collection('queues')
          .doc(queueDocId)
          .update({
            'status': isNext ? 'completed' : 'skipped',
            'completedAt': Timestamp.now(),
          });
          
      print('✅ คิว $currentQueueCode ถูกอัปเดตเป็น ${isNext ? "completed" : "skipped"}');
      
      // Update user's queue status if userId exists
      if (userId.isNotEmpty) {
        QuerySnapshot userQueueSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('myQueue')
            .where('queueCode', isEqualTo: currentQueueCode)
            .get();
            
        for (var doc in userQueueSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('myQueue')
              .doc(doc.id)
              .update({
                'status': isNext ? 'completed' : 'skipped',
                'completedAt': Timestamp.now(),
              });
        }
        
        // Add 2 coins to user if service is completed (isNext = true)
        if (isNext && userId.isNotEmpty) {
          try {
            // Check if user has a coins field
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
                
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              
              // If coins field exists, increment by 2
              if (userData.containsKey('coins')) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'coins': FieldValue.increment(2)});
              } else {
                // If coins field doesn't exist, create it with initial value 12 (10 default + 2 reward)
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'coins': 12});
              }
              
              print('✅ Added 2 coins to user $userId successfully');
              
              // Create reward history record
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('rewardHistory')
                  .add({
                    'title': 'Service Completion Reward',
                    'coins': '+2 coins',
                    'rewardId': 'SVC-${currentQueueCode}',
                    'redeemedAt': Timestamp.now(),
                    'status': 'confirmed',
                    'confirmedAt': Timestamp.now(),
                    'confirmedBy': restaurantId,
                    'description': 'Reward for completing service at $currentQueueCode'
                  });
            }
          } catch (e) {
            print('❌ Error adding coins to user: $e');
          }
        }
      }
      
      // ลบคิวจาก Firestore ทันที (ไม่ใช้ delay)
      try {
        await FirebaseFirestore.instance
            .collection('queues')
            .doc(queueDocId)
            .delete();
            
        print('✅ ลบคิว $currentQueueCode ออกจาก database เรียบร้อยแล้ว');
      } catch (deleteError) {
        print('❌ เกิดข้อผิดพลาดในการลบคิว: $deleteError');
      }
      
      // ปิด loading indicator
      Navigator.of(context, rootNavigator: true).pop();
    }
    
    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${isNext ? 'ให้บริการเสร็จสิ้น' : 'ข้าม'}คิว $currentQueueCode แล้ว"),
      ),
    );
    
    // Refresh data from Firestore for accuracy
    // Small delay to let the user see the change
    await Future.delayed(const Duration(milliseconds: 300));
    await fetchWalkInQueues();
    
  } catch (e) {
    print('Error updating queue: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตคิว: $e')),
    );
    // ปิด loading indicator ในกรณีเกิดข้อผิดพลาด
    Navigator.of(context, rootNavigator: true).pop();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)))
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
                            image: widget.restaurantData!['restaurantImage'] !=
                                    null
                                ? DecorationImage(
                                    image: MemoryImage(
                                      base64Decode(widget
                                          .restaurantData!['restaurantImage']),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              widget.restaurantData!['restaurantImage'] == null
                                  ? const Icon(Icons.restaurant,
                                      color: Colors.grey, size: 30)
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.restaurantData!['name'] ??
                                    'Your Restaurant',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.restaurantData!['location'] ?? 'No location'}',
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
                  label: 'ข้ามคิว',
                  onPressed: () => _updateQueue(index, false),
                ),
                navigationButton(
                  icon: Icons.arrow_forward,
                  label: 'ให้บริการเสร็จ',
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
  bool isLoading = true;
  List<Map<String, dynamic>> reservations = [];
  List<Map<String, dynamic>> upcomingReservations = [];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    if (widget.restaurantData != null) {
      fetchReservations();
    }
  }

  Future<void> fetchReservations() async {
  try {
    setState(() => isLoading = true);

    final restaurantId = widget.restaurantData?['restaurantId'];
    if (restaurantId == null) return;

    // ดึงคิวประเภท reservation ทั้งหมด
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('isReservation', isEqualTo: true)
        .get();

    upcomingReservations = [];
    reservations = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final item = {
        'id': data['queueCode'] ?? '',
        'seat': data['numberOfPersons'].toString(),
        'time': data['bookingTime'] != null
            ? (data['bookingTime'] as Timestamp)
                .toDate()
                .toString()
                .substring(11, 16)
            : '-',
        'status': data['status'] ?? 'waiting',
        'docId': doc.id,
        'completedAt': data['completedAt'], // เพิ่มเวลาที่เสร็จสิ้น
        'timestamp': data['timestamp'], // เพิ่มการเก็บ timestamp เพื่อใช้ในการเรียงลำดับ
      };

      if (data['status'] == 'completed') {
        reservations.add(item);
      } else {
        upcomingReservations.add(item);
      }
    }

    // เรียงลำดับ upcomingReservations ตาม timestamp (เก่าสุดอยู่บนสุด)
    upcomingReservations.sort((a, b) {
      var aTime = a['timestamp'] is Timestamp ? 
          (a['timestamp'] as Timestamp).millisecondsSinceEpoch : 0;
      var bTime = b['timestamp'] is Timestamp ? 
          (b['timestamp'] as Timestamp).millisecondsSinceEpoch : 0;
      return aTime.compareTo(bTime); // เรียงจากน้อยไปมาก (เก่าสุดอยู่บนสุด)
    });

    // เรียงลำดับรายการ completed ตามเวลาที่เสร็จสิ้น (ล่าสุดอยู่ก่อน)
    reservations.sort((a, b) {
      var aTime = a['completedAt'] is Timestamp ? 
          (a['completedAt'] as Timestamp).millisecondsSinceEpoch : 0;
      var bTime = b['completedAt'] is Timestamp ? 
          (b['completedAt'] as Timestamp).millisecondsSinceEpoch : 0;
      return bTime.compareTo(aTime); // เรียงจากมากไปน้อย
    });

    // จำกัดให้มีเพียง 3 รายการเท่านั้น
    if (reservations.length > 3) {
      reservations = reservations.sublist(0, 3);
    }

    setState(() {});
  } catch (e) {
    print("🔥 Error loading reservations: $e");
  } finally {
    setState(() => isLoading = false);
  }
}



Future<String?> getUserIdForQueue(String queueCode, String? restaurantId) async {
  try {
    // พยายามค้นหา userId จากคอลเลกชั่น queues อีกครั้ง
    final querySnapshot = await FirebaseFirestore.instance
      .collection('queues')
      .where('queueCode', isEqualTo: queueCode)
      .where('restaurantId', isEqualTo: restaurantId)
      .get();
      
    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs[0].data();
      if (data['userId'] != null && data['userId'].toString().isNotEmpty) {
        return data['userId'];
      }
    }
    
    // ถ้ายังไม่พบ ลองค้นหาใน users/*/myQueue
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    
    for (var userDoc in usersSnapshot.docs) {
      final myQueueSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userDoc.id)
        .collection('myQueue')
        .where('queueCode', isEqualTo: queueCode)
        .get();
        
      if (myQueueSnapshot.docs.isNotEmpty) {
        return userDoc.id; // ถ้าพบคิวนี้ใน myQueue ของผู้ใช้ใด ให้ใช้ ID ของผู้ใช้นั้น
      }
    }
    
    return null; // ถ้าไม่พบ userId ทั้งสองวิธี
  } catch (error) {
    print('Error finding userId: $error');
    return null;
  }
}


 void markAsComplete(int index) async {
  final completedRes = upcomingReservations[index];

  // ดึง docId เพื่อใช้ลบออกจาก Firestore
  final docId = completedRes['docId'];

  try {
    // อัปเดตสถานะเป็น completed ก่อนลบ (ถ้าต้องการ)
    await FirebaseFirestore.instance
        .collection('advanceBookings')
        .doc(docId)
        .update({'status': 'completed'});

    // ลบจาก Firestore ถ้าไม่ต้องการเก็บ
    // await FirebaseFirestore.instance.collection('advanceBookings').doc(docId).delete();

    setState(() {
      // 1️⃣ ใส่ไว้ที่ท้ายของ reservation
      completedRes['status'] = 'completed';
      reservations.add(completedRes);

      // 2️⃣ ถ้ามีเกิน 3 อัน → ลบตัวแรกสุดออก
      if (reservations.length > 3) {
        reservations.removeAt(0);
      }

      // 3️⃣ ลบจาก upcoming
      upcomingReservations.removeAt(index);
    });

    print('✅ Reservation moved to completed list.');
  } catch (e) {
    print('❌ Error completing reservation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error completing reservation: $e")),
    );
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B2323)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏪 ร้านอาหาร ( รูป ชื่อ ที่อยู่ )
                Row(
                  children: [
                    // แก้ไขส่วนนี้เพื่อใช้รูปภาพจาก database
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        image: widget.restaurantData?['restaurantImage'] != null
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Decode(widget.restaurantData!['restaurantImage']),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.restaurantData?['restaurantImage'] == null
                          ? const Icon(Icons.restaurant, color: Colors.grey, size: 25)
                          : null,
                    ),
                    const SizedBox(width: 10),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurantData?['name'] ?? 'Your Restaurant',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '📍 ${widget.restaurantData?['location'] ?? 'Unknown location'}',
            style: const TextStyle(color: Colors.black, fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    ),
                  ],
                ),
                const SizedBox(height: 16),
                  const Text(
                    'Reservation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // ✅ จองสำเร็จแล้ว (completed) สูงสุด 3 card
                  if (reservations.isNotEmpty)
                    ...reservations
                        .take(3)
                        .map((res) => buildReservationCard(
                              res,
                              reservations.indexOf(res),
                            ))
                        .toList()
                  else
                    const Center(
                      child: Text(
                        "No reservations have been completed yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (upcomingReservations.isNotEmpty) ...[
                    const Text(
                      'Upcoming',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingReservations.length,
                      itemBuilder: (context, index) {
                        return buildUpcomingCard(
                            upcomingReservations[index], index);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget buildReservationCard(Map<String, dynamic> res, int index) {
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
                  onPressed: res['status'] == 'completed'
                      ? null
                      : () async {
                          try {
                            final docId =
                                res['docId']; // ต้องแน่ใจว่ามี key นี้
                            await FirebaseFirestore.instance
                                .collection('queues')
                                .doc(docId)
                                .delete();

                            setState(() {
                              upcomingReservations
                                  .removeAt(index); // หรือ .removeWhere(...)
                            });

                            print('✅ Deleted reservation $docId');
                          } catch (e) {
                            print('❌ Error deleting reservation: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("Error deleting reservation: $e")),
                            );
                          }
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

  

  Widget buildUpcomingCard(Map<String, dynamic> res, int index) {
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
                  Text(res['id']),
                  Text("Seat : ${res['seat']}"),
                  Text("Booked Time : ${res['time']}"),
                  Text("Status : ${res['status']}"),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    markCompletedFromUpcoming(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Complete"),
                ),
                const SizedBox(height: 8),
                IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    try {
      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B2323)),
        ),
      );
      
      final docId = upcomingReservations[index]['docId'];
      final userId = upcomingReservations[index]['userId'];
      final queueCode = upcomingReservations[index]['id'];
      
      print('🔍 กำลังลบคิวรหัส: $queueCode (ID: $docId)');
      
      // อัปเดตสถานะก่อน
      await FirebaseFirestore.instance
          .collection('queues')
          .doc(docId)
          .update({
            'status': 'cancelled',
            'cancelledAt': Timestamp.now(),
            'cancelledBy': 'restaurant',
          });
          
      print('✅ อัปเดตสถานะคิว $queueCode เป็น cancelled แล้ว');
      
      // อัปเดทข้อมูลใน myQueue ของผู้ใช้
      if (userId != null) {
        // ค้นหาเอกสารใน myQueue ของผู้ใช้
        QuerySnapshot userQueueSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('myQueue')
            .where('queueCode', isEqualTo: queueCode)
            .get();

        // ถ้ามีข้อมูล ให้อัพเดทสถานะทุกเอกสารที่พบ
        if (userQueueSnapshot.docs.isNotEmpty) {
          for (var doc in userQueueSnapshot.docs) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('myQueue')
                .doc(doc.id)
                .update({
                  'status': 'cancelled',
                  'cancelledAt': Timestamp.now(),
                  'notificationMessage': 'คิวของคุณถูกทางร้านยกเลิก',
                  'notificationSent': true,
                });
          }
        }
        
        // ส่งการแจ้งเตือน
        try {
          await _notificationService.showNotification(
            id: queueCode.hashCode,
            title: 'การจองของคุณถูกยกเลิก',
            body: 'คิวของคุณถูกทางร้านยกเลิก',
            payload: 'reservation_cancelled:$queueCode',
          );
        } catch (notificationError) {
          print('❌ Error sending notification: $notificationError');
        }
      }
      
      // ลบคิวจาก Firestore ทันที (ไม่ใช้ delay)
      try {
        await FirebaseFirestore.instance
            .collection('queues')
            .doc(docId)
            .delete();
            
        print('✅ ลบคิว $queueCode ออกจาก database เรียบร้อยแล้ว');
      } catch (deleteError) {
        print('❌ เกิดข้อผิดพลาดในการลบคิว: $deleteError');
        throw deleteError; // ส่ง error ไปที่ catch block ด้านนอก
      }

      // ปิด loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        upcomingReservations.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบการจองเรียบร้อยแล้ว")),
      );
    } catch (e) {
      // ปิด loading indicator ในกรณีเกิดข้อผิดพลาด
      Navigator.of(context, rootNavigator: true).pop();
      
      print('❌ Error deleting reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการลบคิว: $e")),
      );
    }
  },
)
              ],
            ),
          ],
        ),
      ),
    );
  }

  

  void markCompletedFromUpcoming(int index) async {
  if (index >= 0 && index < upcomingReservations.length) {
    final completedItem = upcomingReservations[index];
    final docId = completedItem['docId'];
    var userId = completedItem['userId']; // อาจเป็น null หรือค่าว่าง
    final queueCode = completedItem['id']; // รหัสคิว

    try {
      // แสดง loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B2323)),
        ),
      );
      
      print('🔍 กำลังทำรายการ Complete คิวรหัส: $queueCode (ID: $docId)');
      
      // ถ้าไม่มี userId ให้พยายามค้นหาอีกครั้ง
      if (userId == null || userId.toString().isEmpty) {
        print('⚠️ ไม่พบ userId สำหรับคิว $queueCode พยายามค้นหาเพิ่มเติม...');
        final restaurantId = widget.restaurantData?['restaurantId'];
        userId = await getUserIdForQueue(queueCode, restaurantId);
        
        if (userId != null) {
          print('✅ พบ userId: $userId สำหรับคิว $queueCode จากการค้นหาเพิ่มเติม');
          
          // อัปเดต userId ในเอกสารคิวด้วย เพื่อให้ครั้งต่อไปไม่ต้องค้นหาอีก
          await FirebaseFirestore.instance
              .collection('queues')
              .doc(docId)
              .update({'userId': userId});
        } else {
          print('❌ ไม่พบ userId สำหรับคิว $queueCode แม้จะค้นหาเพิ่มเติมแล้ว');
        }
      }
      
      // บันทึกเวลาที่ทำรายการเสร็จ
      final Timestamp completionTime = Timestamp.now();
      
      // อัปเดตสถานะใน Firestore - collection queues
      await FirebaseFirestore.instance
          .collection('queues')
          .doc(docId)
          .update({
            'status': 'completed',
            'completedAt': completionTime,
            'notificationSent': true,
            'completedBy': widget.restaurantData?['restaurantId'] ?? 'unknown',
          });

      print('✅ อัปเดตสถานะคิว $queueCode เป็น completed แล้ว');

      // ถ้ามี userId (หลังจากค้นหาเพิ่มเติมแล้ว) ให้อัปเดทข้อมูลและเพิ่ม coins
      if (userId != null && userId.toString().isNotEmpty) {
        try {
          // ค้นหาเอกสารใน myQueue ของผู้ใช้
          QuerySnapshot userQueueSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('myQueue')
              .where('queueCode', isEqualTo: queueCode)
              .get();

          // ถ้ามีข้อมูล ให้อัพเดทสถานะทุกเอกสารที่พบ
          if (userQueueSnapshot.docs.isNotEmpty) {
            for (var doc in userQueueSnapshot.docs) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('myQueue')
                  .doc(doc.id)
                  .update({
                    'status': 'completed',
                    'completedAt': completionTime,
                    'notificationMessage': 'ทำการเช็คอินเรียบร้อยแล้ว และได้รับ 2 coins!',
                    'notificationSent': true,
                  });
                  
              print('✅ อัพเดทสถานะคิว $queueCode เป็น completed ในฝั่ง user แล้ว');
            }
          } else {
            print('⚠️ ไม่พบข้อมูลคิว $queueCode ใน myQueue ของผู้ใช้ - พยายามสร้างรายการใหม่');
            
            // สร้างรายการใน myQueue หากไม่มี
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('myQueue')
                .add({
                  'queueCode': queueCode,
                  'status': 'completed',
                  'completedAt': completionTime,
                  'timestamp': completionTime,
                  'restaurantId': widget.restaurantData?['restaurantId'],
                  'restaurantName': widget.restaurantData?['name'] ?? 'Restaurant',
                  'notificationMessage': 'คุณได้รับบริการเรียบร้อยแล้ว และได้รับ 2 coins!',
                  'notificationSent': true,
                });
                
            print('✅ สร้างรายการคิวใหม่ใน myQueue ของผู้ใช้ $userId สำเร็จ');
          }

          // เพิ่ม 2 coins ให้ผู้ใช้
          try {
            // ตรวจสอบว่าผู้ใช้มีฟิลด์ coins หรือไม่
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
                
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              
              // ถ้ามีฟิลด์ coins แล้ว ให้เพิ่ม 2
              if (userData.containsKey('coins')) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'coins': FieldValue.increment(2)});
                print('✅ เพิ่ม coins จำนวน 2 ให้ผู้ใช้ $userId (มี ${userData['coins']} coins ก่อนหน้านี้)');
              } else {
                // ถ้ายังไม่มีฟิลด์ coins ให้สร้างและให้ค่าเริ่มต้นที่ 12 (10 เริ่มต้น + 2 รางวัล)
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'coins': 12});
                print('✅ สร้างฟิลด์ coins และตั้งค่าเป็น 12 (10+2) สำหรับผู้ใช้ $userId');
              }
              
              // สร้างประวัติการได้รับ coins ในคอลเลกชัน rewardHistory
              String? restaurantId = widget.restaurantData?['restaurantId'];
              String restaurantName = widget.restaurantData?['name'] ?? 'Restaurant';
              
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('rewardHistory')
                  .add({
                    'title': 'Reservation Completion Reward',
                    'coins': '+2 coins',
                    'rewardId': 'RSV-${queueCode}',
                    'redeemedAt': completionTime,
                    'status': 'confirmed',  // ตั้งค่าเป็น confirmed ทันที เนื่องจากทางร้านเป็นคนให้
                    'confirmedAt': completionTime,
                    'confirmedBy': restaurantId,
                    'description': 'Reward for completing reservation at $restaurantName (Queue: $queueCode)'
                  });
              
              print('✅ สร้างประวัติ reward สำหรับผู้ใช้ $userId สำเร็จ');
              
              // ส่งการแจ้งเตือน
              try {
  await _notificationService.showNotification(
    id: queueCode.hashCode,
    title: 'คิวร้าน ${widget.restaurantData?['name'] ?? 'Restaurant'}',
    body: 'ทำการเช็คอินเรียบร้อยแล้ว และได้รับ 2 coins!',
    payload: 'reservation_completed:$queueCode',
  );
} catch (notificationError) {
  print('❌ Error sending notification: $notificationError');
}
            } else {
              print('⚠️ ไม่พบข้อมูลผู้ใช้ $userId - พยายามสร้างผู้ใช้ใหม่');
              
              // สร้างผู้ใช้ใหม่หากไม่มี
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .set({
                    'coins': 12,  // เริ่มต้นด้วย 10+2 coins
                    'createdAt': completionTime,
                    'lastUpdated': completionTime,
                  });
                  
              // สร้างประวัติการได้รับ coins
              String? restaurantId = widget.restaurantData?['restaurantId'];
              String restaurantName = widget.restaurantData?['name'] ?? 'Restaurant';
              
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('rewardHistory')
                  .add({
                    'title': 'Reservation Completion Reward',
                    'coins': '+2 coins',
                    'rewardId': 'RSV-${queueCode}',
                    'redeemedAt': completionTime,
                    'status': 'confirmed',
                    'confirmedAt': completionTime,
                    'confirmedBy': restaurantId,
                    'description': 'Reward for completing reservation at $restaurantName (Queue: $queueCode)'
                  });
                  
              print('✅ สร้างผู้ใช้ใหม่พร้อมกับ coins และประวัติรางวัลสำเร็จ');
            }
          } catch (e) {
            print('❌ Error adding coins to user: $e');
          }
        } catch (userUpdateError) {
          print('❌ Error updating user data: $userUpdateError');
        }
      } else {
        print('⚠️ ไม่สามารถค้นหา userId สำหรับคิว $queueCode ได้ ไม่สามารถเพิ่ม coins ได้');
        
        // แสดงข้อความแจ้งเตือนให้ผู้ใช้งานทราบ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ไม่พบข้อมูลผู้ใช้สำหรับคิวนี้ ไม่สามารถเพิ่ม coins ได้"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // ลบคิวจาก Firestore ทันที (แทนที่การใช้ delay)
      try {
        print('🗑️ กำลังลบคิว $queueCode จาก Firestore...');
        await FirebaseFirestore.instance
            .collection('queues')
            .doc(docId)
            .delete();
            
        print('✅ ลบคิว $queueCode ออกจาก database เรียบร้อยแล้ว');
      } catch (deleteError) {
        print('❌ เกิดข้อผิดพลาดในการลบคิว: $deleteError');
        // ไม่ throw error เพื่อให้โค้ดยังทำงานต่อไปแม้จะลบไม่สำเร็จ
      }

      // ปิด loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        // อัปเดตใน local state
        completedItem['status'] = 'completed';
        completedItem['completedAt'] = completionTime;
        
        // เพิ่มรายการใหม่ที่ตำแหน่งแรกของ reservations (ล่าสุดอยู่บนสุด)
        reservations.insert(0, completedItem);
        
        // ถ้ามีมากกว่า 3 รายการ ให้ลบรายการสุดท้าย (เก่าสุด)
        if (reservations.length > 3) {
          reservations.removeLast();
        }
        
        // ลบรายการจาก upcoming
        upcomingReservations.removeAt(index);
      });

      // แสดงข้อความแจ้งเตือนตามสถานการณ์
      if (userId != null && userId.toString().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ทำรายการสำเร็จ ผู้ใช้ได้รับ 2 coins แล้ว และลบคิวเรียบร้อย"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ทำรายการสำเร็จ แต่ไม่สามารถเพิ่ม coins ได้เนื่องจากไม่พบผู้ใช้"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // ปิด loading indicator ในกรณีเกิดข้อผิดพลาด
      Navigator.of(context, rootNavigator: true).pop();
      
      print('❌ Error updating reservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  Map<String, dynamic>? _rewardInfo;
  bool _showSuccess = false;

  Future<void> _submitReward() async {
  String rewardId = _rewardNumberController.text.trim();
  if (rewardId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter Reward ID")),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _rewardInfo = null;
    _showSuccess = false;
  });

  // Show processing dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B2323)),
    ),
  );

  try {
    // ค้นหา reward ใน rewardHistory ของผู้ใช้ทุกคน
    QuerySnapshot userSnapshot = await _firestore.collection('users').get();
    bool found = false;
    String? userId;
    String? rewardDocId;

    for (var userDoc in userSnapshot.docs) {
      QuerySnapshot rewardSnapshot = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('rewardHistory')
          .where('rewardId', isEqualTo: rewardId)
          .where('status', isEqualTo: 'pending') // เฉพาะที่ยังรอการยืนยัน
          .get();

      if (rewardSnapshot.docs.isNotEmpty) {
        // พบ reward ที่ตรงกัน
        DocumentSnapshot rewardDoc = rewardSnapshot.docs.first;
        rewardDocId = rewardDoc.id;
        userId = userDoc.id;
        Map<String, dynamic> rewardData = rewardDoc.data() as Map<String, dynamic>;

        // อัพเดตสถานะเป็น confirmed
        await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('rewardHistory')
            .doc(rewardDoc.id)
            .update({
              'status': 'confirmed',
              'confirmedAt': Timestamp.now(),
              'confirmedBy': widget.restaurantData?['restaurantId'] ?? 'unknown'
            });

        // เก็บข้อมูลเพื่อแสดงผล
        setState(() {
          _rewardInfo = rewardData;
          _showSuccess = true;
        });

        found = true;
        break;
      }
    }

    // ปิด loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (found) {
      // แสดงผลแบบ success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reward confirmed successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reward ID not found or already confirmed"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    // ปิด loading dialog ในกรณีเกิดข้อผิดพลาด
    Navigator.of(context, rootNavigator: true).pop();
    
    print("Error submitting reward: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            
            // ปุ่ม Submit
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReward,
              child: _isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)
                  )
                : const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2323),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            
            // แสดงข้อมูลรางวัล
            if (_rewardInfo != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _showSuccess ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _showSuccess 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                          : const Icon(Icons.info, color: Colors.blue, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          _showSuccess ? 'Reward Confirmed!' : 'Reward Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _showSuccess ? Colors.green : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Reward ID: ${_rewardInfo!['rewardId']}'),
                    Text('Reward: ${_rewardInfo!['title']}'),
                    Text('Redeemed: ${_formatDate(_rewardInfo!['redeemedAt'])}'),
                    Text('Amount: ${_rewardInfo!['coins']}'),
                    if (_showSuccess) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'This reward has been successfully confirmed.',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      if (timestamp is Timestamp) {
        DateTime dateTime = timestamp.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
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
                      ? MemoryImage(
                          base64Decode(restaurantData!['restaurantImage']))
                      : null,
                  child: restaurantData!['restaurantImage'] == null
                      ? const Icon(Icons.restaurant,
                          size: 50, color: Colors.grey)
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
                title: "Edit Restaurant",
                page: EditRestaurantScreen(restaurantData: restaurantData),
              ),
              const SizedBox(height: 20),
              buildSettingCard(
                context,
                icon: Icons.local_offer,
                title: "Edit Promotions",
                page: EditPromotionScreen(restaurantData: restaurantData),
              ),
              
              const SizedBox(height: 140),
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
