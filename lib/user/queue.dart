import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

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
      body: Padding(
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

            var allQueues = snapshot.data!.docs;

            // Separate walk-in and booking queues using isReservation field
            // แก้เป็น:
var walkInQueues = allQueues.where((q) {
  final data = q.data() as Map<String, dynamic>;
  return !(data['isReservation'] ?? false);
}).toList();

var bookingQueues = allQueues.where((q) {
  final data = q.data() as Map<String, dynamic>;
  return data['isReservation'] == true;
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
    );
  }
}

class QueueCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const QueueCard({super.key, required this.data});

  @override
  State<QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  int countBefore = -1; // -1 = not loaded yet

  @override
  void initState() {
    super.initState();
    _calculateWaitingCount();
  }

  Future<void> _calculateWaitingCount() async {
    final currentTimestamp = widget.data['timestamp'] as Timestamp?;
    final restaurantId = widget.data['restaurantId'];

    if (currentTimestamp != null && restaurantId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('myQueue')
          .where('isReservation', isEqualTo: false)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      final queues = querySnapshot.docs;

      final count = queues.where((doc) {
        final ts = doc['timestamp'];
        if (ts is Timestamp) {
          return ts.toDate().isBefore(currentTimestamp.toDate());
        }
        return false;
      }).length;

      if (mounted) {
        setState(() {
          countBefore = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final title = data['restaurantName'] ?? '';
    final location = data['restaurantLocation'] ?? '';
    final queueType = data['status'] ?? '';
    final queueNumber = countBefore >= 0 ? '$countBefore' : '-';
    final queueCode = data['queueCode'] ?? '';

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
  
  final time = data['timestamp'] != null
      ? (data['timestamp'] as Timestamp).toDate()
      : null;

  final timeFormatted = time != null
      ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}"
      : 'N/A';

  final dateFormatted = time != null
      ? "${time.day} ${_monthName(time.month)} ${time.year}"
      : 'N/A';
      
  // Calculate number of people before the user in queue
  int countBefore = 0;
  
  final currentTimestamp = data['timestamp'] as Timestamp?;
  final restaurantId = data['restaurantId'];

  if (currentTimestamp != null && restaurantId != null) {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('myQueue')
        .where('isReservation', isEqualTo: false)
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final queues = querySnapshot.docs;

    countBefore = queues.where((doc) {
      final ts = doc['timestamp'];
      if (ts is Timestamp) {
        return ts.toDate().isBefore(currentTimestamp.toDate());
      }
      return false;
    }).length;
  }

  showDialog(
    context: context,
    builder: (context) {
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B2323), // Fallback color if no image
                  image: DecorationImage(
                    image: AssetImage('assets/images/famtime.jpeg'),
                    fit: BoxFit.cover,
                    onError: null, // Handle image loading error
                  ),
                ),
                child: const Center(
                  child: Text(
                    'R', // First letter as fallback
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                      Text(
                        '$countBefore',
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
}

void _showBookingPopup(BuildContext context, Map<String, dynamic> data) {
  // Extract data from Firestore document
  final restaurantName = data['restaurantName'] ?? '';
  final location = data['restaurantLocation'] ?? '';
  final queueCode = data['queueCode'] ?? '';
  final seat = data['numberOfPersons']?.toString() ?? 'N/A';
  final tableType = data['tableType'] ?? 'N/A';
  
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
      
  final createdTimeFormatted = createdAt != null
      ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}:${createdAt.second.toString().padLeft(2, '0')}"
      : 'N/A';

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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8B2323), // Fallback color
                    image: DecorationImage(
                      image: AssetImage('assets/images/famtime.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'R', // First letter as fallback
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                  '*กรุณามาแสดงตัวก่อนถึงเวลาเรียกคิว 10 นาที*',
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