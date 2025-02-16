import 'package:flutter/material.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Text(
          'Oura',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My queue ( Walk in )',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            QueueCard(
              title: 'Fam Time',
              location: 'Siam Square Soi 4',
              queueType: 'Waiting',
              queueNumber: '31',
              queueCode: '#Q097',
              isReservation: false,
            ),
            SizedBox(height: 32),
            Text(
              'Booking ( Queue in advance )',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            QueueCard(
              title: 'Fam Time',
              location: 'Siam Square Soi 4',
              queueType: 'Time',
              queueNumber: '13:30',
              queueCode: '#R001',
              isReservation: true,
            ),
          ],
        ),
      ),
      
    );
  }
}

class QueueCard extends StatelessWidget {
  final String title;
  final String location;
  final String queueType;
  final String queueNumber;
  final String queueCode;
  final bool isReservation;

  const QueueCard({super.key, 
    required this.title,
    required this.location,
    required this.queueType,
    required this.queueNumber,
    required this.queueCode,
    this.isReservation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: QueuePage(),
  ));
}
