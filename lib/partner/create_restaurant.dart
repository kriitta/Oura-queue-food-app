import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../system/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant App',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const CreateRestaurantPage(),
    );
  }
}

class CreateRestaurantPage extends StatefulWidget {
  const CreateRestaurantPage({super.key});

  @override
  _CreateRestaurantPageState createState() => _CreateRestaurantPageState();
}

class _CreateRestaurantPageState extends State<CreateRestaurantPage> {
  File? _restaurantImage;  // เพิ่มการประกาศตัวแปร _restaurantImage
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
          _restaurantImage = File(pickedFile.path); // เก็บภาพร้าน
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B2323),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Oura",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Restaurant",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

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
                            ? FileImage(_restaurantImage!) // ใช้ _restaurantImage ที่ประกาศไว้
                            : null,
                        child: _restaurantImage == null
                            ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[700])
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _pickImage(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B2323),
                        side: const BorderSide(color: Color(0xFF8B2323)),
                      ),
                      child: const Text("Upload Image"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ช่องกรอกข้อมูลร้าน
              _buildTextField("Name Restaurant", _nameController),
              const SizedBox(height: 10),
              _buildTextField("Location", _locationController),
              const SizedBox(height: 10),

              // ส่วนอัปโหลดรูปโปรโมชัน
              const Text("Promotion", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF8B2323)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _promotionImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_promotionImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Upload an image for promotion"),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _pickImage(true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B2323),
                                side: const BorderSide(color: Color(0xFF8B2323)),
                              ),
                              child: const Text("Upload Image"),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilledButton("Create", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ThankYouPage()),
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
          borderSide: const BorderSide(color: Color(0xFF8B2323)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF8B2323)),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่ม Create (Filled Button)
  Widget _buildFilledButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B2323),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}


class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF8B2323),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Oura",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
          ),
        ),
      ),
      body: Center(
        // ✅ ทำให้ทุกอย่างอยู่ตรงกลาง
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // ✅ จัดให้อยู่ตรงกลางแนวตั้ง
            crossAxisAlignment:
                CrossAxisAlignment.center, // ✅ จัดให้อยู่ตรงกลางแนวนอน
            children: [
              const Text(
                "Thank You !",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Image.asset('assets/images/oura-character.png',
                  height: 150), // ✅ รูปภาพตรงกลาง
              const SizedBox(height: 20),
              const Text(
                "Thank you for choosing Oura!\n"
                "Please wait while the admin verify.\n"
                "Keep your notifications on, and we'll notify\n"
                "you once the verification is complete.",
                textAlign: TextAlign.center, // ✅ จัดข้อความให้อยู่ตรงกลาง
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2323),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Log out",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
