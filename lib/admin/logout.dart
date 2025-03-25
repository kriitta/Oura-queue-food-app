import 'package:flutter/material.dart';
import '../system/main.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.exit_to_app, size: 100, color: Colors.red[700]), // ✅ ไอคอน Logout
          const SizedBox(height: 20),
          const Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "If you log out, you will need to sign in again to access the admin panel.",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  // ✅ ปิด Modal และยกเลิก Logout
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  side: const BorderSide(color: Color(0xFF8B2323)),
                ),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B2323), fontSize: 16)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2323),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
