import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditRestaurantScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  
  const EditRestaurantScreen({Key? key, this.restaurantData}) : super(key: key);

  @override
  _EditRestaurantScreenState createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  File? _image;
  bool _isEditing = false; // สถานะการแก้ไข
  TextEditingController _nameController = TextEditingController(text: "Fam Time");
  TextEditingController _locationController = TextEditingController(text: "Siam Square Soi 4");

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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

  void _saveChanges() {
    // บันทึกการเปลี่ยนแปลง
    setState(() {
      _isEditing = false; // ปิดโหมดแก้ไข
    });
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing; // เปลี่ยนสถานะการแก้ไข
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
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
                            backgroundImage: _image != null ? FileImage(_image!) : AssetImage('assets/images/famtime.jpeg') as ImageProvider,
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
