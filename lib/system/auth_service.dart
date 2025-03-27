import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/main.dart';
import '../partner/create_restaurant.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ตรวจสอบผู้ใช้ปัจจุบันและนำทางไปยังหน้าที่เหมาะสม
  Future<void> handleUserAuthentication(BuildContext context) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // ตรวจสอบว่าผู้ใช้เป็น partner หรือไม่
        DocumentSnapshot partnerDoc = await _firestore
            .collection('partners')
            .doc(currentUser.uid)
            .get();
        
        if (partnerDoc.exists) {
          Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
          
          // ตรวจสอบว่า partner ได้สร้างร้านอาหารไปแล้วหรือไม่
          if (partnerData.containsKey('hasSubmittedRestaurant') && 
              partnerData['hasSubmittedRestaurant'] == true) {
            // กรณีที่สร้างร้านอาหารไปแล้ว นำทางไปยังหน้า ThankYouPage
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ThankYouPage()),
            );
          } else {
            // กรณีที่ยังไม่ได้สร้างร้านอาหาร นำทางไปยังหน้าสร้างร้านอาหาร
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CreateRestaurantPage()),
            );
          }
        } else {
          // กรณีที่เป็น user ทั่วไป นำทางไปยังหน้าหลักของ user
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuraApp()),
          );
        }
      }
    } catch (e) {
      print('Error in handleUserAuthentication: $e');
    }
  }
}