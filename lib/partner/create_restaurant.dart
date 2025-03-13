import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: CreateRestaurantPage(),
    );
  }
}

class CreateRestaurantPage extends StatefulWidget {
  @override
  _CreateRestaurantPageState createState() => _CreateRestaurantPageState();
}

class _CreateRestaurantPageState extends State<CreateRestaurantPage> {
  File? _restaurantImage;
  File? _promotionImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Future<void> _pickImage(bool isPromotion) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isPromotion) {
          _promotionImage = File(pickedFile.path);
        } else {
          _restaurantImage = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B2323),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Oura",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้าย
            children: [
              // Title "Create Restaurant"
              Text(
                "Create Restaurant",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // โลโก้ร้าน (รูปวงกลมอยู่ตรงกลาง)
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _restaurantImage != null
                            ? FileImage(_restaurantImage!)
                            : null,
                        child: _restaurantImage == null
                            ? Icon(Icons.camera_alt,
                                size: 40, color: Colors.grey[700])
                            : null,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _pickImage(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF8B2323),
                        side: BorderSide(color: Color(0xFF8B2323)),
                      ),
                      child: Text("Upload Image"),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // ช่องกรอกข้อมูลร้าน
              _buildTextField("Name Restaurant", _nameController),
              SizedBox(height: 10),
              _buildTextField("Location", _locationController),
              SizedBox(height: 10),

              // ส่วนอัปโหลดรูปโปรโมชัน
              Text("Promotion", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF8B2323)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _promotionImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              Image.file(_promotionImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Upload an image for promotion"),
                            SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _pickImage(true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF8B2323),
                                side: BorderSide(color: Color(0xFF8B2323)),
                              ),
                              child: Text("Upload Image"),
                            ),
                          ],
                        ),
                ),
              ),

              // ปุ่ม Back & Create

              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOutlinedButton("Back", () => Navigator.pop(context)),
                  _buildFilledButton("Create", () {
                    // เมื่อกด Create ให้ไปหน้า Thank You
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThankYouPage()),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF8B2323)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF8B2323)),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่ม Back (Outlined Button)
  Widget _buildOutlinedButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF8B2323),
        side: BorderSide(color: Color(0xFF8B2323)),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }

  // ฟังก์ชันสร้างปุ่ม Create (Filled Button)
  Widget _buildFilledButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8B2323),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

class ThankYouPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B2323),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Oura",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          ),
        ),
      ),
      body: Center( // ✅ ทำให้ทุกอย่างอยู่ตรงกลาง
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ จัดให้อยู่ตรงกลางแนวตั้ง
            crossAxisAlignment: CrossAxisAlignment.center, // ✅ จัดให้อยู่ตรงกลางแนวนอน
            children: [
              Text(
                "Thank You !",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Image.asset('assets/images/oura-character.png', height: 150), // ✅ รูปภาพตรงกลาง
              SizedBox(height: 20),
              Text(
                "Thank you for choosing Oura!\n"
                "Please wait while the admin verify.\n"
                "Keep your notifications on, and we'll notify\n"
                "you once the verification is complete.",
                textAlign: TextAlign.center, // ✅ จัดข้อความให้อยู่ตรงกลาง
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ✅ กดแล้วกลับไปหน้าแรก
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B2323),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Log out", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

