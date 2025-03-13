import 'package:flutter/material.dart';

class EditPromotionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              "back",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),
        leadingWidth: 120,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Promotion",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF8B2323)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text("promo-restaurant.jpg"),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOutlinedButton("Change Image"),
                SizedBox(width: 10),
                _buildOutlinedButton("Delete Image"),
              ],
            ),
            SizedBox(height: 20),
            _buildUploadImageSection(), 
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Color(0xFF8B2323)),
      ),
      child: Text(text, style: TextStyle(color: Color(0xFF8B2323))),
    );
  }

  Widget _buildUploadImageSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF8B2323)), 
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "เพิ่มรูปภาพสำหรับแสดงโปรโมชั่น",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF8B2323)),
            ),
            child: Text(
              "Upload Image",
              style: TextStyle(color: Color(0xFF8B2323)),
            ),
          ),
        ],
      ),
    );
  }
}