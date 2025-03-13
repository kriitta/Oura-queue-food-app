import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditRestaurantScreen extends StatefulWidget {
  @override
  _EditRestaurantScreenState createState() => _EditRestaurantScreenState();
}

class _EditRestaurantScreenState extends State<EditRestaurantScreen> {
  File? _image;

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
                  SizedBox(width: 48),
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
                    _buildTextField("Name Restaurant", "Fam Time"),
                    SizedBox(height: 15),
                    _buildTextField("Location", "Siam Square Soi 4"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        SizedBox(height: 5),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B2323)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B2323), width: 2),
            ),
            suffixIcon: Icon(Icons.edit, color: Color(0xFF8B2323)),
          ),
        ),
      ],
    );
  }
}
