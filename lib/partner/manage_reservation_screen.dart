import 'package:flutter/material.dart';

class ManageReservationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "จัดการเวลาจอง",
        style: TextStyle(color: Colors.white), ),
        backgroundColor: Color(0xFF8B2323),
      ),
      body: Center(
        child: Text("หน้าจัดการเวลาจอง"),
      ),
    );
  }
}