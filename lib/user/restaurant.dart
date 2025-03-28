import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';

class RestaurantDetailPage extends StatefulWidget {
  final String image;
  final String name;
  final String location;
  final int queue;
  final Color backgroundColor;
  final List<String> promotionImages;
  final bool isFirestoreImage;
  final String restaurantId;
  final double? distance; // Parameter for distance

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
    this.distance, // Include distance parameter
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _pageController = PageController();
  bool _isLoading = false;
  double? _distance; // Variable to store distance
  bool _isLoadingDistance = false; // Loading state for distance calculation

  @override
  void initState() {
    super.initState();
    _distance = widget.distance;
    if (_distance == null || _distance! < 0) {
      _fetchRestaurantCoordinates();
    }
  }

  // Function to fetch restaurant coordinates and calculate distance
  Future<void> _fetchRestaurantCoordinates() async {
    setState(() {
      _isLoadingDistance = true;
    });

    try {
      // Get restaurant coordinates from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        double? latitude = data['latitude'] is double ? data['latitude'] : null;
        double? longitude = data['longitude'] is double ? data['longitude'] : null;

        if (latitude != null && longitude != null) {
          // Check location permission
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.always || 
              permission == LocationPermission.whileInUse) {
            // Get user's current position
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high
            );

            // Calculate distance
            double calculatedDistance = _calculateDistance(
              position.latitude,
              position.longitude,
              latitude,
              longitude
            );

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

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Pi/180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2*R*asin(sqrt(a)) where R = 6371 km
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

                  // Number of persons
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

  // Function to add queue now in Firestore - combine implementations from both files
  Future<void> _addQueueNow(String tableType, int numberOfPersons) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if user is logged in
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

      // Create new queue data
      Map<String, dynamic> queueData = {
        'userId': currentUser.uid,
        'restaurantId': widget.restaurantId,
        'restaurantName': widget.name,
        'tableType': tableType,
        'numberOfPersons': numberOfPersons,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
      };

      // Add queue to Firestore
      DocumentReference queueRef = await FirebaseFirestore.instance
          .collection('queues')
          .add(queueData);

      // Add to myQueue of user (from second file)
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
        'queueCode': 'W-${queueRef.id.substring(0, 5).toUpperCase()}',
        'queueNumber': '-', // No specific time yet
        'isReservation': false,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increase queue count in restaurant
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .update({
        'queueCount': FieldValue.increment(1),
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

  // Merge both implementations of queue in advance dialog, incorporating date picker from second file
  void _showQueueInAdvanceDialog() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int persons = 1;
    String selectedTableType = '1-2 persons';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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

                    // Date selection (from second file)
                    const Text('Select booking date:',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
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
                            selectedDate = picked;
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

                    // Time selection
                    const Text(
                      'Select booking time:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
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

                    const SizedBox(height: 20),

                    // Table type selection (from first file)
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

                    // Number of persons
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
                              int maxPersons = selectedTableType == '1-2 persons'
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
                            backgroundColor: const Color(0xFF8B2323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            // Create full datetime from date and time
                            final fullDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            _addQueueInAdvance(fullDateTime, persons, selectedTableType);
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
            );
          },
        );
      },
    );
  }

  // Combined implementation for advance booking
  Future<void> _addQueueInAdvance(
      DateTime bookingDateTime, int persons, String tableType) async {
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

      // Add to advanceBookings collection
      Map<String, dynamic> advanceBookingData = {
        'userId': currentUser.uid,
        'restaurantId': widget.restaurantId,
        'restaurantName': widget.name,
        'bookingTime': Timestamp.fromDate(bookingDateTime),
        'numberOfPersons': persons,
        'tableType': tableType, // Add table type to booking data
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('advanceBookings')
          .add(advanceBookingData);

      // Add to user's myQueue collection
      try {
        print('🟢 กำลังเพิ่มข้อมูลลง myQueue');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('myQueue')
            .add({
          'restaurantId': widget.restaurantId,
          'restaurantName': widget.name,
          'restaurantLocation': widget.location,
          'bookingTime': Timestamp.fromDate(bookingDateTime),
          'numberOfPersons': persons,
          'tableType': tableType, // Add table type to myQueue
          'status': 'Booked',
          'queueNumber':
              '${bookingDateTime.hour.toString().padLeft(2, '0')}:${bookingDateTime.minute.toString().padLeft(2, '0')}',
          'queueCode': 'R-${docRef.id.substring(0, 5).toUpperCase()}',
          'isReservation': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ เพิ่มลง myQueue สำเร็จ');
      } catch (e) {
        print('❌ เพิ่มลง myQueue ไม่สำเร็จ: $e');
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
    // Format distance text
    String distanceText = _distance != null && _distance! >= 0 
        ? '${_distance!.toStringAsFixed(1)} km' 
        : _isLoadingDistance ? 'กำลังคำนวณระยะทาง...' : 'ไม่ทราบระยะทาง';

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
                        Expanded(
                          child: Text(
                            widget.location,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
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
                        // Add refresh button for distance
                        if (!_isLoadingDistance)
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onPressed: _fetchRestaurantCoordinates,
                            tooltip: 'รีเฟรชระยะทาง',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (_isLoadingDistance)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
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
                      count: widget.promotionImages.length,
                      effect: const ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Color(0xFF8B2323),
                        dotColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Method to display restaurant image (supports both asset and base64)
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

  // Method to display promotion carousel
  Widget _buildPromotionCarousel() {
    if (widget.promotionImages.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
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
            itemCount: widget.promotionImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showPromotionPopup(
                      widget.promotionImages[index], widget.isFirestoreImage);
                },
                child: _buildPromotionImage(widget.promotionImages[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  // Method to build promotion image
  Widget _buildPromotionImage(String imagePath) {
    if (widget.isFirestoreImage && imagePath.isNotEmpty) {
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
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
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
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
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

  // Method to build reservation option buttons
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