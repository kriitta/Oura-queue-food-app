import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPromotionScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  
  const EditPromotionScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _EditPromotionScreenState createState() => _EditPromotionScreenState();
}

class _EditPromotionScreenState extends State<EditPromotionScreen> {
  List<Uint8List> _images = []; // เก็บข้อมูลภาพในรูปแบบ Uint8List

  // ฟังก์ชันในการเลือกภาพจากเครื่อง
  Future<void> _pickImage(int index) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // แปลงไฟล์เป็น Uint8List
      setState(() {
        if (index >= 0 && index < _images.length) {
          _images[index] = bytes; // เปลี่ยนภาพในตำแหน่งที่เลือก
        }
      });
    }
  }

  // ฟังก์ชันลบภาพจาก _images
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index); // ลบภาพตามดัชนีที่เลือก
    });
  }

  // ฟังก์ชันอัปโหลดภาพใหม่
  void _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // แปลงไฟล์เป็น Uint8List
      setState(() {
        _images.add(bytes); // เพิ่มภาพใหม่เข้าไปใน List
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B2323)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Promotion",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.normal,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            // ปรับให้ปุ่ม Upload Image อยู่ข้างบน
            _buildUploadImageSection(),
            const SizedBox(height: 20),
            // แสดงรูปทั้งหมดที่อัพโหลดใน Card ใหม่
            _images.isEmpty
                ? Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF8B2323)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text("No Image Selected",
                          style: TextStyle(color: Colors.black)),
                    ),
                  )
                : Container(
                    height: 500,
                    width: double.infinity,
                    child: ListView.builder(
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(26), // เพิ่มความโค้งมน
                            ),
                            elevation: 10, // เพิ่มความลึกให้กับการ์ด
                            shadowColor: Colors.black
                                .withOpacity(0.3), // ปรับความมืดของเงา
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    _images[
                                        index], // ใช้ Image.memory สำหรับแสดงภาพใน Web
                                    width: double.infinity,
                                    height: 250, // ให้ภาพแสดงเต็มขนาด
                                    fit: BoxFit
                                        .contain, // ใช้ BoxFit.contain เพื่อให้ภาพไม่ยืด
                                  ),
                                ),
                                // แถบปุ่ม Edit และ Delete ที่ด้านล่างของการ์ด
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8B2323), // เปลี่ยนพื้นหลังให้เป็นสีขาว
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ปุ่ม Change Image
                                      _buildTextButton(
                                          "Change Image",
                                          Colors.white,
                                          Color(0xFF8B2323),
                                          _pickImage,
                                          index),
                                      const SizedBox(width: 10),
                                      // ปุ่ม Delete Image
                                      _buildTextButton(
                                          "Delete",
                                          Colors.red.shade400,
                                          Colors.white,
                                          _removeImage,
                                          index),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUploadImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Color(0xFF8B2323),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Add promotion",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _uploadImage, // เมื่อกดจะเรียกฟังก์ชัน pick image
            style: ElevatedButton.styleFrom(
              foregroundColor: Color(0xFF8B2323), backgroundColor: Colors.white,
              side: BorderSide(color: Color(0xFF8B2323), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              minimumSize: Size(200, 50), // ปรับขนาดให้ปุ่มไม่ยาวเกินไป
            ),
            child: const Text(
              "Upload Image",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่ม TextButton สำหรับ Edit และ Delete
  Widget _buildTextButton(String text, Color bgColor, Color textColor,
    Function(int) onPressed, int index) {
  return Container(
    decoration: BoxDecoration(
      color: bgColor, // พื้นหลังสีขาว
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextButton(
      onPressed: () => onPressed(index), // เรียกใช้ฟังก์ชันตามที่กำหนด
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
}