import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPromotionScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurantData;
  final String? restaurantId;
  
  const EditPromotionScreen({
    Key? key, 
    this.restaurantData,
    this.restaurantId,
  }) : super(key: key);

  @override
  _EditPromotionScreenState createState() => _EditPromotionScreenState();
}

class _EditPromotionScreenState extends State<EditPromotionScreen> {
  List<Uint8List> _images = []; // เก็บข้อมูลภาพในรูปแบบ Uint8List
  bool _isLoading = false;
  final PageController _previewController = PageController();
  int _currentPage = 0;
  String? _restaurantId; // ตัวแปรสำหรับเก็บ document ID ของร้านอาหาร
  final TextEditingController _manualIdController = TextEditingController();
  bool _showManualInput = false;
  String _errorMessage = ''; // เก็บข้อความผิดพลาด

  @override
  void initState() {
    super.initState();
    _determineRestaurantId();
  }

  // ฟังก์ชันค้นหา document ID ของร้านอาหาร
  Future<void> _determineRestaurantId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ตรวจสอบผู้ใช้ที่ล็อกอินอยู่
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('📱 ผู้ใช้ล็อกอินอยู่: ${currentUser.uid}');
        
        // 2. ดึงข้อมูล partner จาก Firestore
        DocumentSnapshot partnerDoc = await FirebaseFirestore.instance
            .collection('partners')
            .doc(currentUser.uid)
            .get();
            
        if (partnerDoc.exists) {
          Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
          
          // 3. ถ้าพบข้อมูล partner และมี restaurantId
          if (partnerData.containsKey('restaurantId') && partnerData['restaurantId'] != null) {
            String docId = partnerData['restaurantId'] as String;
            print('📱 พบ document ID ของร้านอาหารจาก partner: $docId');
            
            // 4. ตรวจสอบว่า document ID นี้มีอยู่จริงในคอลเลกชัน restaurants
            DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
                .collection('restaurants')
                .doc(docId)
                .get();
                
            if (restaurantDoc.exists) {
              print('✅ พบข้อมูลร้านอาหารในฐานข้อมูล');
              setState(() {
                _restaurantId = docId;
              });
              
              // บันทึกลง SharedPreferences
              await _saveRestaurantId(docId);
              
              // โหลดข้อมูลโปรโมชั่นจากร้านอาหาร
              await _loadExistingPromotions();
              return;
            } else {
              print('⚠️ ไม่พบข้อมูลร้านอาหารใน restaurants collection');
            }
          }
        }
      }
      
      // ถ้าไม่สามารถหา document ID จาก partner ได้ ให้ลองวิธีอื่นๆ
      
      // 1. ลองโหลด restaurant ID จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString('current_restaurant_id');
      
      if (savedId != null && savedId.isNotEmpty) {
        print('📱 พบ restaurant ID ที่บันทึกไว้: $savedId');
        
        // ตรวจสอบว่า ID นี้มีอยู่จริงในฐานข้อมูล
        DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(savedId)
            .get();
            
        if (restaurantDoc.exists) {
          setState(() {
            _restaurantId = savedId;
          });
          await _loadExistingPromotions();
          return;
        } else {
          print('⚠️ restaurant ID ที่บันทึกไว้ไม่มีอยู่ในฐานข้อมูลแล้ว');
          await prefs.remove('current_restaurant_id');
        }
      }
      
      // 2. ถ้ามี restaurantId ที่ส่งมาโดยตรง ให้ใช้ค่านั้น
      if (widget.restaurantId != null) {
        print('📱 ใช้ restaurant ID ที่ส่งมาจาก props: ${widget.restaurantId}');
        setState(() {
          _restaurantId = widget.restaurantId;
        });
        await _saveRestaurantId(widget.restaurantId!);
        await _loadExistingPromotions();
        return;
      } 
      
      // 3. ถ้าไม่มี restaurantId แต่มี restaurantData ให้ลองหาจาก restaurantData
      if (widget.restaurantData != null) {
        print('📱 ตรวจสอบ restaurantData: ${widget.restaurantData}');
        
        if (widget.restaurantData!.containsKey('id')) {
          print('📱 พบ id ใน restaurantData: ${widget.restaurantData!['id']}');
          String id = widget.restaurantData!['id'] as String;
          setState(() {
            _restaurantId = id;
          });
          await _saveRestaurantId(id);
          await _loadExistingPromotions();
          return;
        }
        
        if (widget.restaurantData!.containsKey('restaurantId')) {
          print('📱 พบ restaurantId ใน restaurantData: ${widget.restaurantData!['restaurantId']}');
          String id = widget.restaurantData!['restaurantId'] as String;
          setState(() {
            _restaurantId = id;
          });
          await _saveRestaurantId(id);
          await _loadExistingPromotions();
          return;
        }
      }
      
      // 4. ลองหา restaurant ID จาก settings collection
      try {
        DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
            .collection('settings')
            .doc('active_restaurant')
            .get();
            
        if (settingsDoc.exists) {
          Map<String, dynamic> settingsData = settingsDoc.data() as Map<String, dynamic>;
          if (settingsData.containsKey('restaurantId')) {
            print('📱 พบ restaurantId จาก settings: ${settingsData['restaurantId']}');
            String id = settingsData['restaurantId'] as String;
            setState(() {
              _restaurantId = id;
            });
            await _saveRestaurantId(id);
            await _loadExistingPromotions();
            return;
          }
        }
      } catch (e) {
        print('❌ เกิดข้อผิดพลาดในการโหลดจาก settings: $e');
      }
      
      print('⚠️ ไม่พบ restaurant document ID จากทุกแหล่งข้อมูล');
      
      // ถ้าไม่พบจากทุกวิธีข้างต้นให้แสดง UI ให้กรอก ID เอง
      setState(() {
        _showManualInput = true;
      });
      
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการหา restaurant ID: $e');
      
      // แสดง UI ให้กรอก ID เอง
      setState(() {
        _showManualInput = true;
      });
      
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // บันทึก restaurantId ลง SharedPreferences
  Future<void> _saveRestaurantId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_restaurant_id', id);
      print('✅ บันทึก restaurant ID ลง SharedPreferences สำเร็จ');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการบันทึก restaurant ID: $e');
    }
  }

  // ฟังก์ชันใหม่สำหรับรับ ID ที่กรอกเอง
  void _applyManualId() async {
    String id = _manualIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสร้านอาหาร')),
      );
      return;
    }
    
    // ตรวจสอบว่า document ID นี้มีอยู่จริงใน restaurants collection
    try {
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(id)
          .get();
          
      if (restaurantDoc.exists) {
        setState(() {
          _restaurantId = id;
          _showManualInput = false;
        });
        _saveRestaurantId(id);
        _loadExistingPromotions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลร้านอาหารที่ระบุ กรุณาตรวจสอบรหัสร้านอาหารอีกครั้ง')),
        );
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการตรวจสอบรหัสร้านอาหาร: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // โหลดโปรโมชั่นที่มีอยู่แล้วจาก Firestore
  Future<void> _loadExistingPromotions() async {
  if (_restaurantId == null) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    print('📱 กำลังโหลดโปรโมชั่นของร้าน $_restaurantId');
    final DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(_restaurantId)
        .get();
        
    if (restaurantDoc.exists) {
      final data = restaurantDoc.data() as Map<String, dynamic>;
      print('📱 ข้อมูลร้านอาหาร: $data');
      
      if (data.containsKey('promotionImages') && data['promotionImages'] is List) {
        List<dynamic> promotionList = data['promotionImages'];
        print('📱 พบรูปโปรโมชั่น ${promotionList.length} รูป');
        
        if (promotionList.isEmpty) {
          print('⚠️ ไม่มีรูปโปรโมชั่นในฐานข้อมูล');
          setState(() {
            _images = [];
          });
          return;
        }
        
        // แปลง base64 string เป็น Uint8List
        List<Uint8List> loadedImages = [];
        for (var base64Image in promotionList) {
          try {
            if (base64Image is String && base64Image.isNotEmpty) {
              final decodedImage = base64Decode(base64Image);
              loadedImages.add(decodedImage);
              print('✅ แปลงรูปภาพสำเร็จ: ${decodedImage.length} bytes');
            } else {
              print('⚠️ พบข้อมูลรูปภาพที่ไม่ใช่ string หรือว่างเปล่า');
            }
          } catch (e) {
            print('❌ เกิดข้อผิดพลาดในการแปลงรูปภาพ: $e');
          }
        }
        
        if (loadedImages.isNotEmpty) {
          setState(() {
            _images = loadedImages;
          });
          print('✅ โหลดรูปภาพทั้งหมดสำเร็จ: ${_images.length} รูป');
        } else {
          print('⚠️ ไม่สามารถโหลดรูปภาพได้');
          setState(() {
            _images = [];
          });
        }
      } else {
        print('⚠️ ไม่พบข้อมูล promotionImages หรือไม่ใช่รูปแบบ List');
        _checkLegacyPromotionFormat(data);
      }
    } else {
      print('⚠️ ไม่พบข้อมูลร้านอาหาร $_restaurantId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูลร้านอาหาร $_restaurantId')),
      );
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการโหลดโปรโมชั่น: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดโปรโมชั่น: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// เพิ่มฟังก์ชันใหม่เพื่อตรวจสอบรูปแบบข้อมูลโปรโมชันเก่า
void _checkLegacyPromotionFormat(Map<String, dynamic> data) {
  // ตรวจสอบรูปแบบข้อมูลอื่นๆ ที่อาจใช้ในรุ่นเก่า
  if (data.containsKey('promotionImageRefs')) {
    print('📱 พบข้อมูลในรูปแบบ promotionImageRefs จะลองโหลดจาก collection อื่น');
    _loadPromotionFromReferences(data['promotionImageRefs']);
  } else if (data.containsKey('promotionImage')) {
    print('📱 พบข้อมูลในรูปแบบ promotionImage (อาจเป็นรูปเดียว)');
    try {
      var base64Image = data['promotionImage'];
      if (base64Image is String && base64Image.isNotEmpty) {
        setState(() {
          _images = [base64Decode(base64Image)];
        });
        print('✅ โหลดรูปภาพโปรโมชันเดี่ยวสำเร็จ');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการโหลดรูปภาพแบบเก่า: $e');
    }
  }
}

// เพิ่มฟังก์ชันใหม่เพื่อโหลดรูปภาพจาก references
Future<void> _loadPromotionFromReferences(List<dynamic> references) async {
  try {
    List<Uint8List> loadedImages = [];
    for (var ref in references) {
      if (ref is String) {
        try {
          DocumentSnapshot imageDoc = await FirebaseFirestore.instance
              .collection('promotion_images')
              .doc(ref)
              .get();
              
          if (imageDoc.exists) {
            var data = imageDoc.data() as Map<String, dynamic>;
            if (data.containsKey('imageData') && data['imageData'] is String) {
              loadedImages.add(base64Decode(data['imageData']));
            }
          }
        } catch (e) {
          print('❌ ไม่สามารถโหลดรูปจาก reference $ref: $e');
        }
      }
    }
    
    if (loadedImages.isNotEmpty) {
      setState(() {
        _images = loadedImages;
      });
      print('✅ โหลดรูปภาพจาก references สำเร็จ: ${loadedImages.length} รูป');
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการโหลดรูปจาก references: $e');
  }
}
  
  // ฟังก์ชันล้างข้อมูลที่บันทึกไว้
  Future<void> _clearSavedId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_restaurant_id');
      setState(() {
        _restaurantId = null;
        _showManualInput = true;
        _images = [];
      });
      print('✅ ล้างข้อมูล restaurant ID ที่บันทึกไว้แล้ว');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ล้างข้อมูลรหัสร้านอาหารแล้ว')),
      );
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการล้างข้อมูล: $e');
    }
  }

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
      if (_currentPage >= _images.length) {
        _currentPage = _images.isEmpty ? 0 : _images.length - 1;
      }
    });
  }

  // ฟังก์ชันอัปโหลดภาพใหม่
  void _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200, // จำกัดขนาดภาพ
          maxHeight: 1200, // จำกัดขนาดภาพ
          imageQuality: 85 // ลดคุณภาพลงเล็กน้อยเพื่อลดขนาดไฟล์
        );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // แปลงไฟล์เป็น Uint8List
      // ตรวจสอบขนาดไฟล์ (ไม่ควรเกิน 1MB)
      if (bytes.length > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รูปภาพมีขนาดใหญ่เกินไป กรุณาเลือกรูปภาพขนาดเล็กกว่านี้')),
        );
        return;
      }
      
      setState(() {
        _images.add(bytes); // เพิ่มภาพใหม่เข้าไปใน List
        // ไปที่ภาพใหม่ล่าสุดที่เพิ่มเข้ามา
        _currentPage = _images.length - 1;
      });
      
      // ใช้ Future.delayed เพื่อให้แน่ใจว่า setState ได้ทำงานและ PageView ได้ถูกสร้างแล้ว
      if (_images.length > 1) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (_previewController.hasClients) {
            _previewController.animateToPage(
              _currentPage,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          }
        });
      }
    }
  }

  // บันทึกโปรโมชั่นไปยัง Firestore
  Future<void> _savePromotions() async {
  if (_restaurantId == null || _images.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ไม่พบรหัสร้านอาหารหรือไม่มีรูปภาพ')),
    );
    return;
  }
  
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });
  
  try {
    // 1. ตรวจสอบขนาดของข้อมูล
    double totalSizeKB = 0;
    List<String> base64Images = [];
    
    for (var imageBytes in _images) {
      String base64Image = base64Encode(imageBytes);
      totalSizeKB += base64Image.length / 1024;
      base64Images.add(base64Image);
    }
    
    print('💾 ขนาดข้อมูลทั้งหมด: ${totalSizeKB.toStringAsFixed(2)} KB');
    
    if (totalSizeKB > 900) {  // 900KB ให้มี margin สำหรับข้อมูลอื่นๆ
      throw Exception("ข้อมูลมีขนาดใหญ่เกินไป (${totalSizeKB.toStringAsFixed(2)} KB) เกินจำกัด 1MB ของ Firestore");
    }

    // 2. ทดสอบการอัปเดตด้วยวิธีง่ายที่สุดก่อน - ใช้ update แทน set+merge
    print('📤 กำลังอัปเดตข้อมูล...');
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(_restaurantId)
        .update({
          'promotionImages': base64Images
        });
    
    print('✅ บันทึกโปรโมชั่นสำเร็จ!');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('บันทึกโปรโมชั่นสำเร็จ!')),
    );
    
    Navigator.pop(context);
  } catch (e) {
    print('❌ เกิดข้อผิดพลาด: $e');
    setState(() {
      _errorMessage = e.toString();
    });
    
    // ถ้ายังเกิดข้อผิดพลาด ลองวิธีที่ 2: แยกเก็บรูปทีละรูป
    try {
      print('🔄 ลองวิธีที่ 2: แยกเก็บรูปทีละรูป');
      
      // สร้าง collection ใหม่สำหรับเก็บรูปโปรโมชัน
      List<String> imageRefs = [];
      
      for (int i = 0; i < _images.length; i++) {
        String imageId = '${_restaurantId}_promo_${DateTime.now().millisecondsSinceEpoch}_$i';
        String base64Image = base64Encode(_images[i]);
        
        // บันทึกรูปในคอลเลกชัน promotion_images
        await FirebaseFirestore.instance
            .collection('promotion_images')
            .doc(imageId)
            .set({
              'restaurantId': _restaurantId,
              'imageData': base64Image,
              'createdAt': FieldValue.serverTimestamp()
            });
            
        imageRefs.add(imageId);
        print('✅ บันทึกรูปที่ ${i+1}/${_images.length} สำเร็จ');
      }
      
      // อัปเดตเฉพาะ references ในร้านอาหาร
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_restaurantId)
          .update({
            'promotionImageRefs': imageRefs
          });
          
      print('✅ บันทึกข้อมูลสำเร็จด้วยวิธีที่ 2');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกโปรโมชั่นสำเร็จ!')),
      );
      
      Navigator.pop(context);
    } catch (e2) {
      print('❌ วิธีที่ 2 ล้มเหลว: $e2');
      setState(() {
        _errorMessage = 'วิธีที่ 1: $e\nวิธีที่ 2: $e2';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกโปรโมชั่น')),
      );
    }
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// เพิ่มฟังก์ชันใหม่เพื่อบันทึกข้อมูลไว้ในแอปโดยไม่ต้องโหลดใหม่
void _savePromotionLocally(List<String> base64Images) {
  try {
    List<Uint8List> newImages = [];
    for (String base64 in base64Images) {
      newImages.add(base64Decode(base64));
    }
    setState(() {
      _images = newImages;
    });
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการบันทึกข้อมูลในเครื่อง: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    // ถ้าต้องแสดงช่องกรอก ID เอง
    if (_showManualInput) {
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "กรุณาระบุรหัสร้านอาหาร",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "ไม่พบ Document ID ของร้านอาหารอัตโนมัติ กรุณากรอก Document ID ของร้านอาหารในฐานข้อมูล",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _manualIdController,
                decoration: InputDecoration(
                  labelText: "Document ID ของร้านอาหาร",
                  hintText: "เช่น fNSWYi4D5kpe4OIOLJBB",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF8B2323)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF8B2323), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyManualId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2323),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "ยืนยัน",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // หน้าจอหลัก
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B2323)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // เพิ่มปุ่มบันทึก
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _savePromotions,
              child: const Text(
                "บันทึก",
                style: TextStyle(
                  color: Color(0xFF8B2323),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)),
            )
          : Padding(
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
                  // แสดง document ID ของร้านอาหาร (แบบย่อ)
                  Row(
                    children: [
                      // ใช้ Flexible เพื่อให้ข้อความอยู่ในกรอบ
                      Flexible(
                        child: Text(
                          "ID: ${_getShortenedId()}",
                          overflow: TextOverflow.ellipsis, // ตัดข้อความยาวเกินไป
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      // ปุ่มล้างข้อมูล
                      IconButton(
                        iconSize: 18,
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: _clearSavedId,
                        icon: Icon(Icons.refresh, color: Colors.grey[600]),
                        tooltip: "ล้างข้อมูลที่บันทึกไว้",
                      ),
                    ],
                  ),
                  
                  // แสดงข้อความผิดพลาด (ถ้ามี)
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ข้อผิดพลาด: $_errorMessage',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                  // ปรับให้ปุ่ม Upload Image อยู่ข้างบน
                  _buildUploadImageSection(),
                  const SizedBox(height: 20),
                  
                  // แสดงพรีวิวแบบ PageView
                  _buildImagePreviewSection(),
                  
                  const SizedBox(height: 10),
                  
                  // แสดงรายละเอียดของรูปปัจจุบัน
                  if (_images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "รูปที่ ${_currentPage + 1} จาก ${_images.length}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // ปุ่มเปลี่ยนรูป
                              _buildActionButton(
                                "เปลี่ยนรูป",
                                Icons.edit,
                                Colors.blue,
                                () => _pickImage(_currentPage),
                              ),
                              const SizedBox(width: 10),
                              // ปุ่มลบรูป
                              _buildActionButton(
                                "ลบรูป",
                                Icons.delete,
                                Colors.red,
                                () => _removeImage(_currentPage),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  // ฟังก์ชัน Helper สำหรับย่อ ID
  String _getShortenedId() {
    if (_restaurantId == null) return 'ไม่พบรหัสร้านอาหาร';
    if (_restaurantId!.length <= 15) return _restaurantId!;
    return _restaurantId!.substring(0, 12) + '...';
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

  // สร้างส่วนพรีวิวรูปภาพแบบ PageView
  Widget _buildImagePreviewSection() {
    if (_images.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8B2323)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "No Image Selected",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _previewController,
            itemCount: _images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(
                    _images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // เพิ่ม page indicator
        if (_images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_images.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Color(0xFF8B2323)
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
      ],
    );
  }

  // สร้างปุ่มสำหรับการจัดการรูปภาพ
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}