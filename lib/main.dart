import 'package:flutter/material.dart';
import 'package:project_final/restaurant.dart';
import './queue.dart';
import './reward.dart';
import './profile.dart';

void main() {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: const RestaurantListView(),
    
    );
  }
}

class RestaurantListView extends StatelessWidget {
  const RestaurantListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: StatusChip(text: 'Available', isAvailable: true),
          ),
          const RestaurantCard(
            image: 'assets/images/famtime.jpeg',
            name: 'Fam Time',
            location: 'Siam Square Soi 4',
            queue: 21,
            backgroundColor: Color(0xFF8B2323),
            promotionImages: [
              'assets/images/promo-fam.jpg',
              'assets/images/promo-fam2.jpg',
              'assets/images/promo-fam3.jpg',
            ],
          ),
          RestaurantCard(
            image: 'assets/images/cheevitcheeva.jpeg',
            name: 'Cheevit Cheeva',
            location: 'Emspheare Fl. 3',
            queue: 11,
            backgroundColor: Colors.green[400]!,
            promotionImages: const [
              'assets/images/promo-cheevit1.jpg',
              'assets/images/promo-cheevit2.jpg',
              'assets/images/promo-cheevit3.jpg',
            ],
          ),
          RestaurantCard(
            image: 'assets/images/chatrateen.jpeg',
            name: 'Cha Tra Mue',
            location: 'Kasetsart University',
            queue: 999,
            backgroundColor: Colors.red[800]!,
            promotionImages: const [
              'assets/images/promo-cha1.jpg',
              'assets/images/promo-cha2.jpg',
              'assets/images/promo-cha3.jpg',
            ],
          ),
          const RestaurantCard(
            image: 'assets/images/ohkraju.jpeg',
            name: 'Oh Kra Ju',
            location: 'Central World Fl. 2',
            queue: 7,
            backgroundColor: Colors.green,
            promotionImages: [
              'assets/images/promo-oh1.jpg',
              'assets/images/promo-oh2.jpg',
              'assets/images/promo-oh3.jpg',
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: StatusChip(text: 'Unavailable', isAvailable: false),
          ),
          const RestaurantCard(
            image: 'assets/images/ohkraju.jpeg',
            name: 'Oh Kra Ju',
            location: 'Central Lardpao Fl. 1',
            queue: 0,
            isAvailable: false,
            promotionImages: [
              'assets/images/promo-oh1.jpg',
              'assets/images/promo-oh2.jpg',
              'assets/images/promo-oh3.jpg',
            ],
          ),
          const RestaurantCard(
            image: 'assets/images/sizzler.jpeg',
            name: 'Sizzler',
            location: 'Central World Fl. 7',
            queue: 0,
            isAvailable: false,
            promotionImages: [
              'assets/images/promo-siz1.jpg',
              'assets/images/promo-siz2.jpg',
              'assets/images/promo-siz3.jpg',
            ],
          ),
        ],
      ),
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

class RestaurantCard extends StatelessWidget {
  final String image;
  final String name;
  final String location;
  final int queue;
  final Color backgroundColor;
  final bool isAvailable;
  final List<String> promotionImages;

  const RestaurantCard({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    required this.queue,
    this.backgroundColor = const Color(0xFF8B2323),
    this.isAvailable = true,
    required this.promotionImages,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if(isAvailable){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              image: image,
              name: name,
              location: location,
              queue: queue,
              backgroundColor: backgroundColor,
              promotionImages: promotionImages,
            ),
          ),
        );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAvailable ? const Color(0xFF8B2323) : Colors.grey,width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: backgroundColor,
                      child: Center(
                        child: Text(
                          name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isAvailable ? Colors.grey : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            color: isAvailable ? Colors.grey : Colors.grey[600],
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
                          color: isAvailable ? Colors.grey : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Queue : $queue',
                          style: TextStyle(
                            color: isAvailable ? Colors.grey : Colors.grey[600],
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
}