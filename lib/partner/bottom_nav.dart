import 'package:flutter/material.dart';
import 'ourarestaurant.dart';


class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const BottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onNavTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = HomeScreen();
        break;
      case 1:
        nextScreen = ReservationScreen();
        break;
      case 2:
        nextScreen = SettingScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF8B2323),
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onNavTapped(context, index),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Reservation'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ],
    );
  }
}