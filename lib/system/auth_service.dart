import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_final/system/main.dart';
import '../user/main.dart';
import '../partner/create_restaurant.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> handleUserAuthentication(BuildContext context) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot partnerDoc = await _firestore
            .collection('partners')
            .doc(currentUser.uid)
            .get();
        
        if (partnerDoc.exists) {
          Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
          
          if (partnerData.containsKey('hasSubmittedRestaurant') && 
              partnerData['hasSubmittedRestaurant'] == true) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ThankYouPage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const CreateRestaurantPage()),
            );
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          );
        }
      }
    } catch (e) {
      print('Error in handleUserAuthentication: $e');
    }
  }
}