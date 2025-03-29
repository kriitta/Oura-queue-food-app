import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../system/notification_service.dart';
import '../system/queue_monitor_service.dart';

class QueuePage extends StatefulWidget { // เปลี่ยนเป็น StatefulWidget
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with WidgetsBindingObserver {
  final QueueMonitorService _queueMonitor = QueueMonitorService();
  bool _isMonitoringActive = false;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  // เริ่มติดตามคิวเมื่อเปิดหน้านี้
  _startQueueMonitoring();
  
  // เพิ่มการเรียกใช้ฟังก์ชันซิงค์คิวจองล่วงหน้า
  syncReservationQueues();
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // เริ่มหรือหยุดการติดตามคิวตามสถานะของแอพ
    if (state == AppLifecycleState.resumed) {
      _startQueueMonitoring();
    } else if (state == AppLifecycleState.paused) {
      // แอพเข้าสู่พื้นหลัง - ยังคงติดตามคิวเพื่อให้ได้รับการแจ้งเตือน
    }
  }

  void cleanupDeletedQueues(List<DocumentSnapshot> myQueueDocs) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  
  for (var doc in myQueueDocs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String queueCode = data['queueCode'] ?? '';
    String restaurantId = data['restaurantId'] ?? '';
    String status = data['status'] ?? '';
    bool isReservation = data['isReservation'] ?? false;
    
    // ถ้าเป็นการจองล่วงหน้า (isReservation = true) ไม่ต้องลบข้อมูล
    if (isReservation) {
      print('🔒 ไม่ลบข้อมูลการจอง: $queueCode (status: $status)');
      continue; // ข้ามไปคิวถัดไป
    }
    
    // สำหรับคิวแบบ walk-in เท่านั้นที่จะลบถ้าไม่ใช่สถานะ waiting
    if (status != 'waiting') {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('myQueue')
          .doc(doc.id)
          .delete();
      print('Deleted non-waiting queue: $queueCode from user myQueue');
      continue; // ข้ามไปคิวถัดไป
    }
    
    if (queueCode.isEmpty || restaurantId.isEmpty) continue;
    
    // ตรวจสอบว่าคิวนี้ยังมีอยู่ในฐานข้อมูลหลักหรือไม่ (เฉพาะสำหรับคิวแบบ walk-in)
    QuerySnapshot mainQueueSnapshot = await FirebaseFirestore.instance
        .collection('queues')
        .where('queueCode', isEqualTo: queueCode)
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
        
    // ถ้าไม่พบคิวในฐานข้อมูลหลัก หรือคิวในฐานข้อมูลหลักไม่ได้อยู่ในสถานะ waiting แล้ว ให้ลบออกจาก myQueue
    if (mainQueueSnapshot.docs.isEmpty) {
      await _deleteQueueFromMyQueue(currentUser.uid, doc.id, queueCode);
    } else {
      // ตรวจสอบสถานะของคิวในฐานข้อมูลหลัก
      bool shouldDelete = true;
      for (var mainDoc in mainQueueSnapshot.docs) {
        if (mainDoc['status'] == 'waiting') {
          shouldDelete = false;
          break;
        }
      }
      
      if (shouldDelete) {
        await _deleteQueueFromMyQueue(currentUser.uid, doc.id, queueCode);
      }
    }
  }
}

Future<void> syncReservationQueues() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;
  
  try {
    // ดึงข้อมูลคิวจองล่วงหน้าจาก queues collection ที่เป็นของผู้ใช้นี้
    QuerySnapshot reservationSnapshot = await FirebaseFirestore.instance
        .collection('queues')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isReservation', isEqualTo: true)
        .where('status', isEqualTo: 'booked')
        .get();
    
    print('🔍 พบคิวจองล่วงหน้า: ${reservationSnapshot.docs.length} รายการ');
    
    if (reservationSnapshot.docs.isEmpty) return;
    
    // ดึงข้อมูลคิวที่มีอยู่แล้วใน myQueue ของผู้ใช้
    QuerySnapshot myQueueSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .where('isReservation', isEqualTo: true)
        .get();
    
    // สร้าง Set ของ queueCode ที่มีอยู่แล้วใน myQueue
    Set<String> existingQueueCodes = myQueueSnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['queueCode'] as String)
        .toSet();
    
    // ตรวจสอบและเพิ่มคิวที่ยังไม่มีใน myQueue
    int addedCount = 0;
    for (var doc in reservationSnapshot.docs) {
      Map<String, dynamic> queueData = doc.data() as Map<String, dynamic>;
      String queueCode = queueData['queueCode'] ?? '';
      
      // ถ้าคิวนี้ยังไม่มีใน myQueue ให้เพิ่มเข้าไป
      if (queueCode.isNotEmpty && !existingQueueCodes.contains(queueCode)) {
        // ดึงข้อมูลร้านอาหารเพื่อเพิ่มข้อมูลสำหรับการแสดงผล
        DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(queueData['restaurantId'])
            .get();
        
        // สร้าง map ข้อมูลที่จะบันทึกลงใน myQueue
        Map<String, dynamic> myQueueData = {
          ...queueData,
          'restaurantName': restaurantDoc.exists 
              ? (restaurantDoc.data() as Map<String, dynamic>)['name'] ?? 'ร้านอาหาร'
              : 'ร้านอาหาร',
          'restaurantLocation': restaurantDoc.exists 
              ? (restaurantDoc.data() as Map<String, dynamic>)['location'] ?? 'ไม่ระบุสถานที่'
              : 'ไม่ระบุสถานที่',
        };
        
        // บันทึกลงใน myQueue ของผู้ใช้
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('myQueue')
            .add(myQueueData);
        
        addedCount++;
        print('✅ เพิ่มคิว $queueCode เข้า myQueue แล้ว');
      }
    }
    
    print('🔄 ซิงค์คิวจองล่วงหน้าเสร็จสิ้น: เพิ่ม $addedCount คิวใหม่');
    
    // ถ้ามีการเพิ่มข้อมูลใหม่ ให้แสดงแจ้งเตือน
    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('พบและซิงค์คิวจองล่วงหน้า $addedCount รายการ')),
      );
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการซิงค์คิวจองล่วงหน้า: $e');
  }
}

Future<void> saveBookingToUserMyQueue(Map<String, dynamic> bookingData) async {
  try {
    final userId = bookingData['userId'];
    if (userId == null) return;
    
    // ดึงข้อมูลร้านอาหารเพื่อเพิ่มข้อมูลสำหรับการแสดงผล
    DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(bookingData['restaurantId'])
        .get();
    
    // สร้าง map ข้อมูลที่จะบันทึกลงใน myQueue
    Map<String, dynamic> myQueueData = {
      ...bookingData,
      'isReservation': true,  // ตรวจสอบให้แน่ใจว่ามีการตั้งค่านี้
      'status': bookingData['status'] ?? 'booked', // กำหนดค่าเริ่มต้นเป็น 'booked' ถ้าไม่มีค่า
      'restaurantName': restaurantDoc.exists 
          ? (restaurantDoc.data() as Map<String, dynamic>)['name'] ?? 'ร้านอาหาร'
          : 'ร้านอาหาร',
      'restaurantLocation': restaurantDoc.exists 
          ? (restaurantDoc.data() as Map<String, dynamic>)['location'] ?? 'ไม่ระบุสถานที่'
          : 'ไม่ระบุสถานที่',
      'createdAt': bookingData['createdAt'] ?? Timestamp.now(), // เพิ่มเวลาที่สร้าง
    };
    
    // ถ้าไม่มี bookingTime ให้เพิ่มเข้าไปด้วยวันและเวลาปัจจุบัน (สำหรับกรณีที่ไม่มีการระบุเวลาจอง)
    if (!myQueueData.containsKey('bookingTime') || myQueueData['bookingTime'] == null) {
      // สร้างเวลาสำหรับการจองเริ่มต้น (1 ชั่วโมงจากเวลาปัจจุบัน)
      DateTime now = DateTime.now();
      DateTime bookingTime = now.add(const Duration(hours: 1));
      myQueueData['bookingTime'] = Timestamp.fromDate(bookingTime);
    }
    
    // บันทึกลงใน myQueue ของผู้ใช้
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('myQueue')
        .add(myQueueData);
        
    print('✅ บันทึกการจองลงใน myQueue ของผู้ใช้สำเร็จ (ID: ${docRef.id})');
    print('📝 ข้อมูลที่บันทึก: $myQueueData');
    
    return;
  } catch (e) {
    print('❌ Error saving booking to user myQueue: $e');
    throw e; // ส่งต่อ error เพื่อให้ฟังก์ชันที่เรียกใช้รับทราบ
  }
}

void _debugBookingQueue(List<DocumentSnapshot> allQueues) {
  print("🔍 DEBUG: ตรวจสอบข้อมูลการจองทั้งหมด");
  int count = 0;
  
  for (var q in allQueues) {
    final data = q.data() as Map<String, dynamic>;
    if (data['isReservation'] == true) {
      count++;
      print("📋 พบข้อมูลการจอง #$count:");
      print("  - Queue Code: ${data['queueCode']}");
      print("  - Restaurant: ${data['restaurantName']}");
      print("  - Status: ${data['status']}");
      print("  - Is Reservation: ${data['isReservation']}");
      
      if (data['bookingTime'] != null) {
        final bookingTime = (data['bookingTime'] as Timestamp).toDate();
        print("  - Booking Time: ${bookingTime.toString()}");
      }
    }
  }
  
  if (count == 0) {
    print("❌ ไม่พบข้อมูลการจองในระบบ");
  } else {
    print("✅ พบข้อมูลการจองทั้งหมด $count รายการ");
  }
}

// แยกฟังก์ชันลบคิวออกมาเพื่อใช้ซ้ำ
Future<void> _deleteQueueFromMyQueue(String userId, String docId, String queueCode) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('myQueue')
      .doc(docId)
      .delete();
      
  print('Deleted queue: $queueCode from user myQueue');
}


  void _startQueueMonitoring() {
    if (!_isMonitoringActive) {
      _queueMonitor.startMonitoringAllQueues();
      _isMonitoringActive = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String userId = currentUser?.uid ?? '';

  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF8B2323),
      title: const Text(
        'Queue',
        style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
    ),
    body: RefreshIndicator(
      onRefresh: () async {
        await syncReservationQueues(); // เรียกใช้ฟังก์ชันซิงค์เมื่อ pull-to-refresh
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('myQueue')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B2323)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No queues found. Book a queue to get started!'));
            }

            if (snapshot.hasData) {
  for (var doc in snapshot.data!.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String queueCode = data['queueCode'] ?? '';
    String restaurantId = data['restaurantId'] ?? '';
    bool isReservation = data['isReservation'] ?? false;
    
    // ตรวจสอบสถานะใน queues collection
    FirebaseFirestore.instance
        .collection('queues')
        .where('queueCode', isEqualTo: queueCode)
        .where('restaurantId', isEqualTo: restaurantId)
        .get()
        .then((queueSnapshot) {
          if (queueSnapshot.docs.isNotEmpty) {
            var mainQueueDoc = queueSnapshot.docs.first;
            var mainStatus = mainQueueDoc['status'];
            
            // แก้ไขเงื่อนไขตรงนี้ เพื่อให้ตรวจสอบทั้งคิว walk-in และคิวจองล่วงหน้า
            bool needsUpdate = false;
            
            // คิว walk-in สถานะ waiting เปลี่ยนไป
            if (data['status'] == 'waiting' && mainStatus != 'waiting') {
              needsUpdate = true;
            }
            
            // คิวจองล่วงหน้า (booked) มีการเปลี่ยนสถานะเป็น completed หรือ cancelled
            if (isReservation && data['status'] == 'booked' && 
                (mainStatus == 'completed' || mainStatus == 'cancelled')) {
              needsUpdate = true;
            }
            
            // ถ้าจำเป็นต้องอัพเดท
            if (needsUpdate) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('myQueue')
                  .doc(doc.id)
                  .update({'status': mainStatus});
                  
              print('🔄 อัพเดทสถานะคิว $queueCode จาก ${data['status']} เป็น $mainStatus');
            }
          }
        });
  }
}

          var allQueues = snapshot.data!.docs;
          
          // เรียกใช้ฟังก์ชันทำความสะอาดข้อมูลคิวที่ถูกลบ
          cleanupDeletedQueues(allQueues);
          _debugBookingQueue(allQueues);

            // Separate walk-in and booking queues using isReservation field
            var walkInQueues = allQueues.where((q) {
  final data = q.data() as Map<String, dynamic>;
  // กรองเฉพาะคิวที่ยังมีสถานะ "waiting" เท่านั้น
  return !(data['isReservation'] ?? false) && (data['status'] == 'waiting');
}).toList();

// เช่นเดียวกับส่วนกรองคิว Booking
// เช่นเดียวกับส่วนกรองคิว Booking
var bookingQueues = allQueues.where((q) {
  final data = q.data() as Map<String, dynamic>;
  // กรองเฉพาะคิวที่มีสถานะ "booked" เท่านั้น
  return data['isReservation'] == true && (data['status'] == 'booked');
}).toList();


          return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My queue ( Walk in )',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // If no walk-in queues
                  if (walkInQueues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No walk-in queue found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  // Display walk-in queues with spacing
                  for (var queue in walkInQueues) ...[
                    QueueCard(data: queue.data() as Map<String, dynamic>),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 32),

                  const Text(
                    'Booking ( Queue in advance )',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // If no booking queues
                  if (bookingQueues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No booking queue found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  // Display booking queues with spacing
                  for (var queue in bookingQueues) ...[
                    BookingCard(data: queue.data() as Map<String, dynamic>),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    )
    );
  }
}

class QueueCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const QueueCard({super.key, required this.data});

  @override
  State<QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> with AutomaticKeepAliveClientMixin {
  Stream<int>? waitingCountStream;
  bool _hasSetupStream = false;

  @override
  bool get wantKeepAlive => true; // ช่วยรักษา state เมื่อ scroll

  @override
  void initState() {
    super.initState();
    _setupWaitingCountStream();
  }

  @override
  void didUpdateWidget(QueueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ตรวจสอบว่าข้อมูลเปลี่ยนไปหรือไม่
    if (widget.data['restaurantId'] != oldWidget.data['restaurantId'] ||
        (widget.data['timestamp'] != oldWidget.data['timestamp'])) {
      _setupWaitingCountStream();
    }
  }

  void _setupWaitingCountStream() {
    final restaurantId = widget.data['restaurantId'];
    final currentTimestamp = widget.data['timestamp'];
    
    if (restaurantId != null && currentTimestamp is Timestamp) {
      // ใช้ .where() น้อยลงเพื่อเพิ่มโอกาสในการได้ข้อมูลที่ถูกต้อง
      waitingCountStream = FirebaseFirestore.instance
          .collection('queues')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'waiting')
          .snapshots()
          .map((snapshot) {
            print("Stream updated with ${snapshot.docs.length} queues for $restaurantId");
            int count = 0;
            
            for (var doc in snapshot.docs) {
              // ทำการกรองข้อมูลเพิ่มเติมหลังจากได้รับข้อมูล
              final docData = doc.data();
              final isReservation = docData['isReservation'] ?? false;
              
              if (isReservation == false) {
                final ts = docData['timestamp'];
                if (ts is Timestamp && ts.toDate().isBefore(currentTimestamp.toDate())) {
                  count++;
                }
              }
            }
            
            print("Calculated waiting count: $count");
            return count;
          });
      
      _hasSetupStream = true;
    }
  }

  @override
  void dispose() {
    // ทำความสะอาด resources
    waitingCountStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // จำเป็นสำหรับ AutomaticKeepAliveClientMixin
    
    final data = widget.data;
    final title = data['restaurantName'] ?? '';
    final location = data['restaurantLocation'] ?? '';
    final queueType = data['status'] ?? '';
    final queueCode = data['queueCode'] ?? '';

    // กรณีที่ยังไม่ได้สร้าง stream ให้ลองสร้างอีกครั้ง
    if (!_hasSetupStream) {
      _setupWaitingCountStream();
    }

    return GestureDetector(
      onTap: () {
        _showQueuePopup(context, data);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B2323), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.supervised_user_circle_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Your queue : $queueCode',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  queueType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2323),
                  ),
                ),
                const SizedBox(height: 8),
                waitingCountStream != null
                  ? StreamBuilder<int>(
                      stream: waitingCountStream,
                      initialData: 0,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B2323),
                            ),
                          );
                        }
                        
                        // ใช้ data หรือเลข 0 ถ้าไม่มีข้อมูล
                        final queueNumber = snapshot.hasData ? '${snapshot.data}' : '-';
                        
                        // แสดงข้อมูลพร้อม color indicator
                        return Text(
                          queueNumber,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            
                          ),
                        );
                      },
                    )
                  : const Text(
                      '-',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const BookingCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['restaurantName'] ?? '';
    final location = data['restaurantLocation'] ?? '';
    final queueType = data['status'] ?? '';
    final queueCode = data['queueCode'] ?? '';
    final bookingTime = data['bookingTime'] != null
        ? (data['bookingTime'] as Timestamp).toDate()
        : null;

    // Format the date and time for display
    final queueNumber = bookingTime != null
        ? "${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}"
        : 'N/A';
    
    final dateTimeFormatted = bookingTime != null
        ? "${bookingTime.day.toString().padLeft(2, '0')} ${_monthName(bookingTime.month)} ${bookingTime.year} - ${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}"
        : 'N/A';

    return GestureDetector(
      onTap: () {
        _showBookingPopup(context, data);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B2323), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.supervised_user_circle_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Your queue : $queueCode',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  queueType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2323),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  queueNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function for month name conversion
String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

Future<void> _showQueuePopup(BuildContext context, Map<String, dynamic> data) async {
  final restaurantName = data['restaurantName'] ?? '';
  final restaurantLocation = data['restaurantLocation'] ?? '';
  final queueCode = data['queueCode'] ?? 'N/A';
  final seat = data['numberOfPersons']?.toString() ?? 'N/A';
  final tableType = data['tableType'] ?? 'N/A';
  final restaurantId = data['restaurantId'];
  final currentTimestamp = data['timestamp'] as Timestamp?;

  String? restaurantImageBase64;

  if (restaurantId != null) {
    try {
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      if (restaurantDoc.exists) {
        final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
        restaurantImageBase64 = restaurantData['restaurantImage'];
      }
    } catch (e) {
      print('Error loading restaurant image: $e');
    }
  }
  
  final time = data['timestamp'] != null
      ? (data['timestamp'] as Timestamp).toDate()
      : null;

  final timeFormatted = time != null
      ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}"
      : 'N/A';

  final dateFormatted = time != null
      ? "${time.day} ${_monthName(time.month)} ${time.year}"
      : 'N/A';
      
  // สร้าง Stream สำหรับนับจำนวนคนที่รออยู่ก่อน
  Stream<int>? waitingCountStream;
  
  if (restaurantId != null && currentTimestamp != null) {
    // ปรับปรุง query ให้ไม่ซับซ้อนเกินไป และใช้ listener ที่ดีขึ้น
    waitingCountStream = FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          
          for (var doc in snapshot.docs) {
            final docData = doc.data();
            // กรองข้อมูลหลังจากได้รับมาแล้ว
            final isReservation = docData['isReservation'] ?? false;
            final status = docData['status'];
            
            if (!isReservation && status == 'waiting') {
              final ts = docData['timestamp'];
              if (ts is Timestamp && ts.toDate().isBefore(currentTimestamp.toDate())) {
                count++;
              }
            }
          }
          
          return count;
        });
  }

  // ใช้ StatefulBuilder เพื่อให้สามารถอัพเดท UI ในป๊อปอัพได้
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  
                  const Text(
                    'Queue ( walk - in )',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B2323),
                      image: restaurantImageBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(restaurantImageBase64)),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: AssetImage('assets/images/famtime.jpeg'),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: restaurantImageBase64 == null ? const Center(
                      child: Text(
                        'R', // First letter as fallback
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ) : null,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    restaurantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        restaurantLocation,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Your Queue',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            queueCode,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Waiting',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          if (waitingCountStream != null)
                            StreamBuilder<int>(
                              stream: waitingCountStream,
                              initialData: 0,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      
                                    ),
                                  );
                                }
                                
                                final waitingCount = snapshot.hasData ? snapshot.data! : 0;
                                
                                return Text(
                                  '$waitingCount',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    
                                  ),
                                );
                              },
                            )
                          else
                            const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Table Type : $tableType', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seat : $seat', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time : $timeFormatted',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date : $dateFormatted', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    '*ขอสงวนสิทธิ์ในการข้ามคิว กรณีลูกค้าไม่แสดงตน*',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showBookingPopup(BuildContext context, Map<String, dynamic> data) async {
  final restaurantName = data['restaurantName'] ?? '';
  final location = data['restaurantLocation'] ?? '';
  final queueCode = data['queueCode'] ?? '';
  final seat = data['numberOfPersons']?.toString() ?? 'N/A';
  final tableType = data['tableType'] ?? 'N/A';
  
  // Get restaurant image from Firestore
  String? restaurantImageBase64;
  if (data['restaurantId'] != null) {
    final restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(data['restaurantId'])
        .get();

    if (restaurantDoc.exists) {
      final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
      restaurantImageBase64 = restaurantData['restaurantImage'];
    }
  }
  
  // Get booking time
  final bookingTime = data['bookingTime'] != null
      ? (data['bookingTime'] as Timestamp).toDate()
      : null;

  final bookingTimeFormatted = bookingTime != null
      ? "${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}"
      : 'N/A';
      
  // Get creation time
  final createdAt = data['createdAt'] != null
      ? (data['createdAt'] as Timestamp).toDate()
      : null;
      
  final createdDateFormatted = createdAt != null
      ? "${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}"
      : 'N/A';
      
  // Format full booking date and time
  final fullBookingTime = bookingTime != null
      ? "${bookingTime.day} ${_monthName(bookingTime.month)} ${bookingTime.year}"
      : 'N/A';

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                const Text(
                  'Queue ( Booking )',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B2323),
                    image: restaurantImageBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(restaurantImageBase64)),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/famtime.jpeg'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: restaurantImageBase64 == null ? const Center(
                    child: Text(
                      'R', // First letter as fallback
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ) : null,
                ),

                const SizedBox(height: 12),

                Text(
                  restaurantName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Your Queue',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          queueCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Time',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingTimeFormatted,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Table Type : $tableType',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seat : $seat',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date : $fullBookingTime',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booked on : $createdDateFormatted',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  '*ขอสงวนสิทธิ์ในการข้ามคิว กรณีลูกค้าไม่แสดงตนตามเวลาที่จอง*',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: QueuePage(),
  ));
}