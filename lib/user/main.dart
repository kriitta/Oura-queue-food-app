import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:project_final/user/restaurant.dart';
import 'package:geolocator/geolocator.dart';
import 'queue.dart';
import 'reward.dart';
import 'profile.dart';
import 'package:firebase_core/firebase_core.dart';
import '../system/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../system/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final notificationService = NotificationService();
  await notificationService.init();
  await NotificationService().resetAll();

  runApp(const QuraApp());
}

class QuraApp extends StatelessWidget {
  const QuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oura',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B2323),
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const QueuePage(),
    const RewardPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF8B2323),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera_front_rounded),
            label: 'MyQueue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Reward',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Oura',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B2323),
        
      ),
      body: const RestaurantListView(),
    
    );
  }
}

class RestaurantListView extends StatefulWidget {
  const RestaurantListView({super.key});

  @override
  _RestaurantListViewState createState() => _RestaurantListViewState();
}

class _RestaurantListViewState extends State<RestaurantListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;
  Position? _currentPosition;
  bool _isLocationLoading = true;
  
  List<StreamSubscription> _restaurantSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    for (var subscription in _restaurantSubscriptions) {
      subscription.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; 
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); 
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โปรดเปิดบริการตำแหน่ง')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocationLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('การอนุญาตการเข้าถึงตำแหน่งถูกปฏิเสธ')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('การอนุญาตการเข้าถึงตำแหน่งถูกปฏิเสธถาวร')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });
      
      _loadRestaurants();
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการรับตำแหน่ง: $e')),
      );
      
      _loadRestaurants();
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (var subscription in _restaurantSubscriptions) {
        subscription.cancel();
      }
      _restaurantSubscriptions = [];

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('isVerified', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> loadedRestaurants = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        Color backgroundColor = const Color(0xFF8B2323);
        
        bool isAvailable = data['isAvailable'] ?? true;
        
        double? latitude = data['latitude'] is double ? data['latitude'] : null;
        double? longitude = data['longitude'] is double ? data['longitude'] : null;
        
        double distance = -1; // ค่าเริ่มต้นถ้าไม่สามารถคำนวณระยะทางได้
        if (_currentPosition != null && latitude != null && longitude != null) {
          distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            latitude,
            longitude
          );
        }
        
        List<String> promotionImages = [];
        if (data.containsKey('promotionImage') && data['promotionImage'] != null) {
          promotionImages.add(data['promotionImage']);
        }
        
        Map<String, dynamic> restaurant = {
          'id': doc.id,
          'image': data['restaurantImage'],
          'name': data['name'] ?? 'Unnamed Restaurant',
          'location': data['location'] ?? 'No location',
          'latitude': latitude,
          'longitude': longitude,
          'distance': distance,
          'queue': data['queueCount'] ?? 0,
          'backgroundColor': backgroundColor,
          'promotionImages': promotionImages,
          'isAvailable': isAvailable,
        };
        
        loadedRestaurants.add(restaurant);
        
        var subscription = FirebaseFirestore.instance
            .collection('restaurants')
            .doc(doc.id)
            .snapshots()
            .listen((docSnapshot) {
          if (docSnapshot.exists) {
            final updatedData = docSnapshot.data() as Map<String, dynamic>;
            setState(() {
              int index = _restaurants.indexWhere((r) => r['id'] == doc.id);
              if (index != -1) {
                _restaurants[index]['queue'] = updatedData['queueCount'] ?? 0;
                _restaurants[index]['isAvailable'] = updatedData['isAvailable'] ?? true;
              }
            });
          }
        });
        
        _restaurantSubscriptions.add(subscription);
      }
      
      loadedRestaurants.sort((a, b) {
        double distA = a['distance'] as double;
        double distB = b['distance'] as double;
        
        if (distA < 0 && distB < 0) return 0;
        if (distA < 0) return 1;
        if (distB < 0) return -1;
        
        return distA.compareTo(distB);
      });
      
      setState(() {
        _restaurants = loadedRestaurants;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading restaurants: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRestaurants = _restaurants
        .where((restaurant) =>
            restaurant['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search restaurant",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B2323)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF8B2323)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF8B2323)),
              ),
            ),
            style: const TextStyle(color: Color(0xFF8B2323)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: _currentPosition != null ? Colors.green : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _currentPosition != null 
                  ? 'ตำแหน่งของคุณพร้อมแล้ว' 
                  : 'ไม่พบตำแหน่งของคุณ',
                style: TextStyle(
                  color: _currentPosition != null ? Colors.green : Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh, color: Color(0xFF8B2323)),
                label: const Text(
                  'รีเฟรชตำแหน่ง', 
                  style: TextStyle(color: Color(0xFF8B2323))
                ),
              ),
            ],
          ),
        ),

        if (_isLoading || _isLocationLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B2323)),
            ),
          )
        else if (_restaurants.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'ไม่พบร้านอาหาร',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRestaurants,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Section
                    if (filteredRestaurants.any((r) => r['isAvailable']))
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: StatusChip(text: 'Available', isAvailable: true),
                      ),
                    ...filteredRestaurants
                        .where((r) => r['isAvailable'])
                        .map((restaurant) => RestaurantCard(
                              image: restaurant['image'] ?? '',
                              name: restaurant['name'],
                              location: restaurant['location'],
                              distance: restaurant['distance'],
                              queue: restaurant['queue'],
                              backgroundColor: restaurant['backgroundColor'],
                              promotionImages: List<String>.from(restaurant['promotionImages']),
                              isFirestoreImage: true,
                              restaurantId: restaurant['id'],
                            ))
                        .toList(),

                    if (filteredRestaurants.any((r) => !r['isAvailable']))
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: StatusChip(text: 'Unavailable', isAvailable: false),
                      ),
                    ...filteredRestaurants
                        .where((r) => !r['isAvailable'])
                        .map((restaurant) => RestaurantCard(
                              image: restaurant['image'],
                              name: restaurant['name'],
                              location: restaurant['location'],
                              distance: restaurant['distance'],
                              queue: restaurant['queue'],
                              backgroundColor: restaurant['backgroundColor'],
                              promotionImages: List<String>.from(restaurant['promotionImages']),
                              isAvailable: false,
                              isFirestoreImage: true,
                              restaurantId: restaurant['id'],
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final bool isAvailable;

  const StatusChip({
    super.key,
    required this.text,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class RestaurantCard extends StatefulWidget {
  final String image;
  final String name;
  final String location;
  final double distance;
  final int queue;
  final Color backgroundColor;
  final bool isAvailable;
  final List<String> promotionImages;
  final bool isFirestoreImage;
  final String restaurantId;

  const RestaurantCard({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    this.distance = -1,
    required this.queue,
    this.backgroundColor = const Color(0xFF8B2323),
    this.isAvailable = true,
    required this.promotionImages,
    this.isFirestoreImage = false,
    required this.restaurantId,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  Stream<int>? _queueCountStream;
  int _currentQueueCount = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _currentQueueCount = widget.queue; 
    _setupQueueCountStream();
  }

  void _setupQueueCountStream() {
    
    _queueCountStream = FirebaseFirestore.instance
        .collection('queues')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    _subscription = _queueCountStream?.listen((count) {
      if (mounted) {
        setState(() {
          _currentQueueCount = count;
        });
      }
    });
  }

  @override
  void didUpdateWidget(RestaurantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restaurantId != oldWidget.restaurantId) {
      _subscription?.cancel();
      _setupQueueCountStream();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String distanceText = widget.distance >= 0 
        ? '${widget.distance.toStringAsFixed(1)} km' 
        : 'ไม่ทราบระยะทาง';

    return GestureDetector(
      onTap: () {
        if (widget.isAvailable) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailPage(
                image: widget.image,
                name: widget.name,
                location: widget.location,
                queue: _currentQueueCount, 
                backgroundColor: widget.backgroundColor,
                promotionImages: widget.promotionImages,
                isFirestoreImage: widget.isFirestoreImage,
                restaurantId: widget.restaurantId,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isAvailable ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.isAvailable ? const Color(0xFF8B2323) : Colors.grey, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildRestaurantImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.location,
                            style: TextStyle(
                              color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions,
                          size: 16,
                          color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: TextStyle(
                            color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Queue : $_currentQueueCount',
                          style: TextStyle(
                            color: widget.isAvailable ? Colors.grey : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantImage() {
    if (widget.isFirestoreImage && widget.image != null && widget.image.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(widget.image),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage();
          },
        );
      } catch (e) {
        return _buildFallbackImage();
      }
    } else {
      return Image.asset(
        widget.image,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 80,
      height: 80,
      color: widget.backgroundColor,
      child: Center(
        child: Text(
          widget.name.isNotEmpty ? widget.name.substring(0, 1) : "?",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}