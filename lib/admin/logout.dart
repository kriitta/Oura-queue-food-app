import 'package:flutter/material.dart';

class LogoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.exit_to_app, size: 100, color: Colors.red[700]), // ✅ ไอคอน Logout
          SizedBox(height: 20),
          Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            "If you log out, you will need to sign in again to access the admin panel.",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  // ✅ ปิด Modal และยกเลิก Logout
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  side: BorderSide(color: Color(0xFF8B2323)),
                ),
                child: Text("Cancel", style: TextStyle(color: Color(0xFF8B2323), fontSize: 16)),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  // ✅ กลับไปหน้า Login หรือหน้าหลัก
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B2323),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
