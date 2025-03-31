import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';
import '../system/notification_service.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String image;
  final String name;
  final String location;
  final int queue;
  final Color backgroundColor;
  final List<String> promotionImages;
  final bool isFirestoreImage;
  final String restaurantId;
  final double? distance;

  const RestaurantDetailPage({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    required this.queue,
    required this.backgroundColor,
    required this.promotionImages,
    this.isFirestoreImage = false,
    required this.restaurantId,
    this.distance, 
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _pageController = PageController();
  bool _isLoading = false;
  double? _distance; 
  bool _isLoadingDistance = false; 
  List<String> _promotionImages = [];
  bool _isLoadingPromotions = false;

  @override
void initState() {
  super.initState();
  _distance = widget.distance;
  if (_distance == null || _distance! < 0) {
    _fetchRestaurantCoordinates();
  }
  
  _loadPromotions();
}



Future<void> _loadPromotions() async {
  setState(() {
    _isLoadingPromotions = true;
  });
  
  try {
    print('📱 กำลังโหลดโปรโมชั่นของร้าน ${widget.restaurantId}');
    DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .get();
        
    if (restaurantDoc.exists) {
      final data = restaurantDoc.data() as Map<String, dynamic>;
      
      
      if (data.containsKey('promotionImageRefs') && data['promotionImageRefs'] is List) {
        List<dynamic> refs = data['promotionImageRefs'];
        if (refs.isNotEmpty) {
          print('📱 พบข้อมูล promotionImageRefs จำนวน ${refs.length} รายการ');
          
          List<String> loadedImages = [];
          for (String ref in refs.cast<String>()) {
            try {
              DocumentSnapshot imageDoc = await FirebaseFirestore.instance
                  .collection('promotion_images')
                  .doc(ref)
                  .get();
                  
              if (imageDoc.exists) {
                Map<String, dynamic> imageData = imageDoc.data() as Map<String, dynamic>;
                if (imageData.containsKey('imageData') && imageData['imageData'] is String) {
                  loadedImages.add(imageData['imageData']);
                }
              }
            } catch (e) {
              print('❌ ไม่สามารถโหลดรูปจาก ref $ref: $e');
            }
          }
          
          if (loadedImages.isNotEmpty) {
            setState(() {
              _promotionImages = loadedImages;
            });
            print('✅ โหลดโปรโมชันจาก promotionImageRefs ${loadedImages.length} รูปสำเร็จ');
            return;
          }
        }
      }
      
      print('⚠️ ไม่พบข้อมูลโปรโมชั่นในฟอร์แมตที่รองรับ');
      setState(() {
        _promotionImages = [];
      });
    }
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการโหลดโปรโมชัน: $e');
  } finally {
    setState(() {
      _isLoadingPromotions = false;
    });
  }
}

  Future<void> _fetchRestaurantCoordinates() async {
    setState(() {
      _isLoadingDistance = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        double? latitude = data['latitude'] is double ? data['latitude'] : null;
        double? longitude =
            data['longitude'] is double ? data['longitude'] : null;

        if (latitude != null && longitude != null) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);

            double calculatedDistance = _calculateDistance(
                position.latitude, position.longitude, latitude, longitude);

            setState(() {
              _distance = calculatedDistance;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching restaurant coordinates: $e');
    } finally {
      setState(() {
        _isLoadingDistance = false;
      });
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; 
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); 
  }

  void _showQueueNowDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int numberOfPersons = 1;
        String selectedTableType = '1-2 persons';

        void updateNumberOfPersons(String tableType) {
          setState(() {
            selectedTableType = tableType;
            if (tableType == '1-2 persons') {
              numberOfPersons = 1;
            } else if (tableType == '3-6 persons') {
              numberOfPersons = 3;
            } else if (tableType == '7-12 persons') {
              numberOfPersons = 7;
            }
          });
        }

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Queue Now',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Type of tables:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildTableTypeButton(
                        '1-2 persons',
                        Icons.people,
                        selectedTableType,
                        (value) {
                          setState(() {
                            updateNumberOfPersons(value);
                          });
                        },
                      ),
                      _buildTableTypeButton(
                        '3-6 persons',
                        Icons.group,
                        selectedTableType,
                        (value) {
                          setState(() {
                            updateNumberOfPersons(value);
                          });
                        },
                      ),
                      _buildTableTypeButton(
                        '7-12 persons',
                        Icons.groups,
                        selectedTableType,
                        (value) {
                          setState(() {
                            updateNumberOfPersons(value);
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Number of persons:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle,
                            color: Color(0xFF8B2323)),
                        iconSize: 36,
                        onPressed: () {
                          setState(() {
                            int minPersons = selectedTableType == '1-2 persons'
                                ? 1
                                : selectedTableType == '3-6 persons'
                                    ? 3
                                    : 7;
                            if (numberOfPersons > minPersons) numberOfPersons--;
                          });
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          numberOfPersons.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF8B2323)),
                        iconSize: 36,
                        onPressed: () {
                          setState(() {
                            int maxPersons = selectedTableType == '1-2 persons'
                                ? 2
                                : selectedTableType == '3-6 persons'
                                    ? 6
                                    : 12;
                            if (numberOfPersons < maxPersons) numberOfPersons++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(
                                    color: Color(0xFF8B2323), width: 1))),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8B2323),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B2323),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          _addQueueNow(selectedTableType, numberOfPersons);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addQueueNow(String tableType, int numberOfPersons) async {
  try {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาล็อกอินเพื่อจองคิว')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    bool hasActiveQueue = await _hasActiveQueue();
    if (hasActiveQueue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คุณมีคิวที่กำลังรออยู่ในร้านนี้แล้ว กรุณารอให้คิวเสร็จสิ้นก่อนจองใหม่'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final restaurantRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId);
    DocumentSnapshot restaurantDoc = await restaurantRef.get();

    int lastNumber = (restaurantDoc.data()
            as Map<String, dynamic>)['lastWalkInQueueNumber'] ??
        0;

    int nextNumber = (lastNumber + 1) > 999 ? 1 : lastNumber + 1;
    String queueCode = '#Q-${nextNumber.toString().padLeft(3, '0')}';

    Map<String, dynamic> queueData = {
      'userId': currentUser.uid,
      'restaurantId': widget.restaurantId,
      'restaurantName': widget.name,
      'tableType': tableType,
      'numberOfPersons': numberOfPersons,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'queueCode': queueCode,
      'isReservation': false,
    };

    DocumentReference queueRef =
        await FirebaseFirestore.instance.collection('queues').add(queueData);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .add({
      'restaurantId': widget.restaurantId,
      'restaurantName': widget.name,
      'restaurantLocation': widget.location,
      'tableType': tableType,
      'numberOfPersons': numberOfPersons,
      'status': 'waiting',
      'queueCode': queueCode,
      'queueNumber': '-',
      'isReservation': false,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .update({
      'queueCount': FieldValue.increment(1),
      'lastWalkInQueueNumber': nextNumber,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('จองคิวสำเร็จ!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Widget _buildTableTypeButton(String type, IconData icon, String selectedType,
      Function(String) onSelect) {
    bool isSelected = selectedType == type;
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border:
              Border.all(color: isSelected ? Color(0xFF8B2323) : Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF8B2323) : Colors.grey),
            const SizedBox(height: 5),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.brown : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionPopup(String imagePath, bool isFirestoreImage) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isFirestoreImage && imagePath.isNotEmpty
                    ? Image.memory(
                        base64Decode(imagePath),
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQueueInAdvanceDialog() {
    DateTime now = DateTime.now();
    DateTime minimumTime = now.add(const Duration(hours: 2));
    DateTime maximumTime = now.add(const Duration(hours: 24));
    
    DateTime selectedDate = minimumTime;
    TimeOfDay selectedTime = TimeOfDay(hour: minimumTime.hour, minute: minimumTime.minute);
    
    int persons = 1;
    String selectedTableType = '1-2 persons';
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void validateSelectedDateTime() {
              DateTime selectedDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              
              if (selectedDateTime.isBefore(minimumTime)) {
                setState(() {
                  errorMessage = 'กรุณาเลือกเวลาล่วงหน้าอย่างน้อย 2 ชั่วโมง';
                });
              } else if (selectedDateTime.isAfter(maximumTime)) {
                setState(() {
                  errorMessage = 'กรุณาเลือกเวลาไม่เกิน 1 วัน';
                });
              } else {
                setState(() {
                  errorMessage = null;
                });
              }
            }
            
            validateSelectedDateTime();
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Queue in advance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Select booking date:',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 1)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF8B2323),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year, 
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute
                            );
                            validateSelectedDateTime();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B2323)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8B2323),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Select booking time:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        TimeOfDay initialTime = selectedTime;
                        if (selectedDate.year == now.year && 
                            selectedDate.month == now.month && 
                            selectedDate.day == now.day) {
                          if (initialTime.hour < minimumTime.hour || 
                              (initialTime.hour == minimumTime.hour && initialTime.minute < minimumTime.minute)) {
                            initialTime = TimeOfDay(hour: minimumTime.hour, minute: minimumTime.minute);
                          }
                        }
                        
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF8B2323),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            validateSelectedDateTime();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B2323)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B2323),
                          ),
                        ),
                      ),
                    ),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      'Type of tables:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildTableTypeButton(
                          '1-2 persons',
                          Icons.people,
                          selectedTableType,
                          (value) {
                            setState(() {
                              selectedTableType = value;
                              if (value == '1-2 persons') {
                                persons = 1;
                              } else if (value == '3-6 persons') {
                                persons = 3;
                              } else if (value == '7-12 persons') {
                                persons = 7;
                              }
                            });
                          },
                        ),
                        _buildTableTypeButton(
                          '3-6 persons',
                          Icons.group,
                          selectedTableType,
                          (value) {
                            setState(() {
                              selectedTableType = value;
                              persons = 3;
                            });
                          },
                        ),
                        _buildTableTypeButton(
                          '7-12 persons',
                          Icons.groups,
                          selectedTableType,
                          (value) {
                            setState(() {
                              selectedTableType = value;
                              persons = 7;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Number of persons:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Color(0xFF8B2323)),
                          iconSize: 36,
                          onPressed: () {
                            setState(() {
                              int minPersons =
                                  selectedTableType == '1-2 persons'
                                      ? 1
                                      : selectedTableType == '3-6 persons'
                                          ? 3
                                          : 7;
                              if (persons > minPersons) persons--;
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            persons.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF8B2323)),
                          iconSize: 36,
                          onPressed: () {
                            setState(() {
                              int maxPersons =
                                  selectedTableType == '1-2 persons'
                                      ? 2
                                      : selectedTableType == '3-6 persons'
                                          ? 6
                                          : 12;
                              if (persons < maxPersons) persons++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(
                                      color: Color(0xFF8B2323), width: 1))),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8B2323),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorMessage == null 
                                ? const Color(0xFF8B2323)
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: errorMessage == null ? () {
                            final fullDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            
                            if (fullDateTime.isBefore(minimumTime)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาเลือกเวลาล่วงหน้าอย่างน้อย 2 ชั่วโมง')),
                              );
                              return;
                            }
                            
                            if (fullDateTime.isAfter(maximumTime)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาเลือกเวลาไม่เกิน 1 วัน')),
                              );
                              return;
                            }
                            
                            _addQueueInAdvance(
                                fullDateTime, persons, selectedTableType);
                            Navigator.of(context).pop();
                          } : null,
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _hasActiveQueue() async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('myQueue')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('status', whereIn: ['waiting', 'booked']) 
        .get();
    
    return snapshot.docs.isNotEmpty;
  } catch (e) {
    print('❌ เกิดข้อผิดพลาดในการตรวจสอบคิว: $e');
    return false; 
  }
}

Future<void> _addQueueInAdvance(DateTime bookingTime, int persons, String tableType) async {
  try {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาล็อกอินเพื่อจองคิว')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    bool hasActiveQueue = await _hasActiveQueue();
    if (hasActiveQueue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คุณมีคิวที่กำลังรออยู่ในร้านนี้แล้ว กรุณารอให้คิวเสร็จสิ้นก่อนจองใหม่'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId);
    final restaurantDoc = await restaurantRef.get();

    // Get today's key for queue numbering
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    int lastNumber = (restaurantDoc.data() as Map<String, dynamic>)['reservationQueueNumbers']?[todayKey] ?? 0;
    int nextNumber = (lastNumber + 1) > 999 ? 1 : lastNumber + 1;
    String queueCode = '#R-${nextNumber.toString().padLeft(3, '0')}';

    Map<String, dynamic> queueData = {
      'userId': currentUser.uid,
      'restaurantId': widget.restaurantId,
      'restaurantName': widget.name,
      'tableType': tableType,
      'numberOfPersons': persons,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'status': 'booked',
      'queueCode': queueCode,
      'isReservation': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    DocumentReference queueRef = await FirebaseFirestore.instance.collection('queues').add(queueData);

    await FirebaseFirestore.instance.collection('advanceBookings').add({
      'userId': currentUser.uid,
      'restaurantId': widget.restaurantId,
      'restaurantName': widget.name,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'numberOfPersons': persons,
      'tableType': tableType,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'queueCode': queueCode,
    });

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('myQueue').add({
      'restaurantId': widget.restaurantId,
      'restaurantName': widget.name,
      'restaurantLocation': widget.location,
      'tableType': tableType,
      'numberOfPersons': persons,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'status': 'booked',
      'queueCode': queueCode,
      'queueNumber': '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}',
      'isReservation': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await restaurantRef.set({
      'reservationQueueNumbers': {
        todayKey: nextNumber,
      }
    }, SetOptions(merge: true));

    if (bookingTime.isAfter(DateTime.now())) {
      final NotificationService notificationService = NotificationService();
      await notificationService.scheduleQueueAdvanceNotifications(
        restaurantId: widget.restaurantId,
        restaurantName: widget.name,
        bookingTime: bookingTime,
        queueCode: queueCode,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('จองคิวล่วงหน้าสำเร็จ!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    String distanceText = _distance != null && _distance! >= 0
        ? '${_distance!.toStringAsFixed(1)} km'
        : _isLoadingDistance
            ? 'กำลังคำนวณระยะทาง...'
            : 'ไม่ทราบระยะทาง';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF8B2323),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildRestaurantImage(),
                    const SizedBox(height: 20),
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Add distance information
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Queue : ${widget.queue}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Choose the type of reservation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildReservationOption(
                          icon: Icons.groups,
                          title: 'Queue Now',
                          onTap: _showQueueNowDialog,
                        ),
                        _buildReservationOption(
                          icon: Icons.calendar_today,
                          title: 'Queue\nin advance',
                          onTap: _showQueueInAdvanceDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Promotion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPromotionCarousel(),
                    const SizedBox(height: 20),
                    SmoothPageIndicator(
  controller: _pageController,
  count: _promotionImages.isEmpty ? widget.promotionImages.length : _promotionImages.length,
  effect: const ExpandingDotsEffect(
    dotHeight: 8,
    dotWidth: 8,
    activeDotColor: Color(0xFF8B2323),
    dotColor: Colors.grey,
  ),
)
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRestaurantImage() {
    if (widget.isFirestoreImage && widget.image.isNotEmpty) {
      try {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor,
          ),
          child: Center(
            child: ClipOval(
              child: Image.memory(
                base64Decode(widget.image),
                fit: BoxFit.cover,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150,
                    height: 150,
                    color: widget.backgroundColor,
                    child: Center(
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name.substring(0, 1).toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor,
          ),
          child: Center(
            child: Text(
              widget.name.isNotEmpty
                  ? widget.name.substring(0, 1).toUpperCase()
                  : "?",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } else {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.backgroundColor,
        ),
        child: Center(
          child: ClipOval(
            child: Image.asset(
              widget.image,
              fit: BoxFit.cover,
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  color: widget.backgroundColor,
                  child: Center(
                    child: Text(
                      widget.name.isNotEmpty
                          ? widget.name.substring(0, 1).toUpperCase()
                          : "?",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPromotionCarousel() {
  final promotionImages = _promotionImages.isEmpty ? widget.promotionImages : _promotionImages;
  
  if (promotionImages.isEmpty) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: _isLoadingPromotions 
            ? CircularProgressIndicator(color: Color(0xFF8B2323))
            : Text(
                "No Promotions",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
      ),
    );
  }

  return SizedBox(
    height: 200,
    child: Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: promotionImages.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _showPromotionPopup(
                    promotionImages[index], true); 
              },
              child: _buildPromotionImage(promotionImages[index], true), 
            );
          },
        ),
        
      ],
    ),
  );
}

  Widget _buildPromotionImage(String imagePath, [bool isFirestoreImage = false]) {
  isFirestoreImage = isFirestoreImage || widget.isFirestoreImage;
  
  if (isFirestoreImage && imagePath.isNotEmpty) {
    try {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            base64Decode(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ เกิดข้อผิดพลาดในการแสดงรูปภาพ: $error');
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'Image not available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการแปลงรูปภาพ: $e');
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            'Image not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
  } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  Widget _buildReservationOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF8B2323),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}