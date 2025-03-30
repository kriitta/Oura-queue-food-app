import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

// เพิ่มคลาส LocationService ตรงนี้ ก่อนคลาส EditRestaurantScreen
class LocationService {
  // อัปเดตพิกัดจากที่อยู่ (เช่น จากหน้าแอดมิน)
  static Future<bool> updateRestaurantCoordinates(
      String restaurantId, String address) async {
    try {
      // แปลงที่อยู่เป็นพิกัด
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        // อัปเดตใน Firestore
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .update({
          'latitude': location.latitude,
          'longitude': location.longitude,
        });

        print(
            '✅ อัปเดตพิกัดสำเร็จ: $address -> (${location.latitude}, ${location.longitude})');
        return true;
      }

      print('❌ ไม่พบพิกัดสำหรับที่อยู่: $address');
      return false;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัปเดตพิกัด: $e');
      return false;
    }
  }

  // อัปเดตพิกัดโดยตรง (ระบุละติจูด/ลองจิจูด)
  static Future<bool> updateRestaurantCoordinatesDirect(
      String restaurantId, double latitude, double longitude) async {
    try {
      // อัปเดตใน Firestore
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .update({
        'latitude': latitude,
        'longitude': longitude,
      });

      print('✅ อัปเดตพิกัดสำเร็จ: ($latitude, $longitude)');
      return true;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัปเดตพิกัด: $e');
      return false;
    }
  }

  // อัปเดตพิกัดของร้านอาหารทั้งหมดจากที่อยู่
  static Future<void> batchUpdateRestaurantCoordinates() async {
    try {
      // ดึงร้านอาหารทั้งหมดที่ผ่านการยืนยัน
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('isVerified', isEqualTo: true)
          .get();

      print('🔍 พบร้านอาหารทั้งหมด ${snapshot.docs.length} ร้าน');

      int successCount = 0;
      int errorCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // ข้ามร้านที่มีพิกัดแล้ว
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          print('⏩ ข้ามร้าน ${data['name']} เนื่องจากมีพิกัดแล้ว');
          continue;
        }

        // ดึงที่อยู่ร้านอาหาร
        String location = data['location'] ?? '';
        if (location.isEmpty) {
          print('⚠️ ร้าน ${data['name']} ไม่มีข้อมูลที่อยู่');
          errorCount++;
          continue;
        }

        try {
          print('🔄 กำลังแปลงที่อยู่เป็นพิกัด: ${data['name']} - $location');

          // แปลงที่อยู่เป็นพิกัด
          List<Location> locations = await locationFromAddress(location);

          if (locations.isNotEmpty) {
            Location locationData = locations.first;

            // อัปเดตข้อมูลใน Firestore
            await FirebaseFirestore.instance
                .collection('restaurants')
                .doc(doc.id)
                .update({
              'latitude': locationData.latitude,
              'longitude': locationData.longitude,
            });

            print(
                '✅ อัปเดตพิกัดสำเร็จ: ${data['name']} -> (${locationData.latitude}, ${locationData.longitude})');
            successCount++;
          } else {
            print('❌ ไม่พบพิกัดสำหรับที่อยู่: ${data['name']} - $location');
            errorCount++;
          }

          // หน่วงเวลาเล็กน้อยเพื่อไม่ให้ API โดน rate limit
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('❌ เกิดข้อผิดพลาดในการแปลงที่อยู่: ${data['name']} - $e');
          errorCount++;
        }
      }

      print(
          '🏁 อัปเดตเสร็จสิ้น | สำเร็จ: $successCount | ผิดพลาด: $errorCount');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัปเดตแบบกลุ่ม: $e');
    }
  }
}

class EditRestaurantScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;

  const EditRestaurantScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _EditRestaurantScreenState createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  File? _image;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _isCalculatingCoordinates = false; // เพิ่มตัวแปรนี้
  TextEditingController _nameController =
      TextEditingController(text: "Fam Time");
  TextEditingController _locationController =
      TextEditingController(text: "Siam Square Soi 4");
  double? _latitude; // เพิ่มตัวแปรนี้
  double? _longitude; // เพิ่มตัวแปรนี้

  @override
  void initState() {
    super.initState();
    if (widget.restaurantData != null) {
      _isAvailable = widget.restaurantData?['isAvailable'] ?? true;

      _nameController.text = widget.restaurantData!['name'] ?? 'Fam Time';
      _locationController.text =
          widget.restaurantData!['location'] ?? 'Siam Square Soi 4';
      _latitude = widget.restaurantData!['latitude'];
      _longitude = widget.restaurantData!['longitude'];
    }
  }

  // เพิ่มฟังก์ชันนี้
  Future<void> _calculateCoordinates() async {
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกที่อยู่ก่อนคำนวณพิกัด')),
      );
      return;
    }

    setState(() {
      _isCalculatingCoordinates = true;
    });

    try {
      if (widget.restaurantData != null &&
          widget.restaurantData!.containsKey('restaurantId')) {
        String restaurantId = widget.restaurantData!['restaurantId'];

        bool success = await LocationService.updateRestaurantCoordinates(
          restaurantId,
          _locationController.text,
        );

        if (success) {
          // ดึงข้อมูลพิกัดที่อัปเดต
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              _latitude = data['latitude'];
              _longitude = data['longitude'];
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('คำนวณพิกัดสำเร็จ: $_latitude, $_longitude')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบพิกัดสำหรับที่อยู่นี้')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isCalculatingCoordinates = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  void _saveChanges() async {
    // บันทึกการเปลี่ยนแปลง
    setState(() {
      _isLoading =
          true; // ตั้งค่าตัวแปรแสดงสถานะการโหลด (อาจต้องเพิ่มตัวแปรนี้)
    });

    try {
      // ตรวจสอบว่ามี restaurantData และ restaurantId หรือไม่
      if (widget.restaurantData != null &&
          widget.restaurantData!.containsKey('restaurantId')) {
        String restaurantId = widget.restaurantData!['restaurantId'];

        // อัปเดตข้อมูลทั่วไป
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .update({
          'name': _nameController.text,
          'location': _locationController.text,
          'isAvailable': _isAvailable,
          // อัปเดตข้อมูลอื่นๆ ตามที่จำเป็น
        });
        if (_image != null) {
          final imageBytes = await _image!.readAsBytes();
          final base64Image = base64Encode(imageBytes);

          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .update({
            'restaurantImage': base64Image,
          });

          print('✅ รูปร้านถูกอัปโหลดแล้ว');
        }

        // อัปเดตพิกัดจากที่อยู่
        await LocationService.updateRestaurantCoordinates(
            restaurantId, _locationController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      print('Error saving changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    } finally {
      setState(() {
        _isEditing = false; // ปิดโหมดแก้ไข
        _isLoading = false; // ปิดสถานะการโหลด
      });
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing; // เปลี่ยนสถานะการแก้ไข
    });
  }

  @override
  Widget build(BuildContext context) {
    // โค้ดส่วนที่เหลือยังคงเหมือนเดิม
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 5, spreadRadius: 1),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF8B2323)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Edit Restaurant',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  // เพิ่มปุ่ม Edit/Save
                  if (!_isEditing)
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF8B2323)),
                      onPressed: _toggleEditing,
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.save, color: Color(0xFF8B2323)),
                      onPressed: _saveChanges,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (widget.restaurantData?['restaurantImage'] !=
                                            null
                                        ? MemoryImage(base64Decode(
                                            widget.restaurantData![
                                                'restaurantImage']))
                                        : AssetImage(
                                            'assets/images/famtime.jpeg'))
                                    as ImageProvider,
                            backgroundColor: Colors.transparent,
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: _pickImage,
                                child: Text('Upload Image'),
                              ),
                              SizedBox(width: 10),
                              if (_image != null)
                                OutlinedButton(
                                  onPressed: _removeImage,
                                  child: Text('Delete Image'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField("Name Restaurant", _nameController),
                    SizedBox(height: 15),
                    _buildTextField("Location", _locationController),

                    // เพิ่มปุ่มคำนวณพิกัด
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isCalculatingCoordinates
                                  ? null
                                  : _calculateCoordinates,
                              icon: _isCalculatingCoordinates
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.location_searching),
                              label: const Text('คำนวณพิกัดจากที่อยู่'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B2323),
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_latitude != null && _longitude != null)
                              Text(
                                'พิกัดปัจจุบัน: $_latitude, $_longitude',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'สถานะร้านค้า:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                Switch(
                                  value: _isAvailable,
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.red,
                                  onChanged: _isEditing
                                      ? (value) {
                                          setState(() {
                                            _isAvailable = value;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            Text(
                              _isAvailable
                                  ? 'เปิดให้บริการ'
                                  : 'ปิดร้านชั่วคราว',
                              style: TextStyle(
                                color: _isAvailable ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: _isEditing, // เปิด/ปิดฟิลด์ตามโหมดการแก้ไข
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}