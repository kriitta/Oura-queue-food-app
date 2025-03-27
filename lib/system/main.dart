import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'signup.dart';
import '../system/firebase_options.dart';
import '../user/main.dart';
import '../partner/create_restaurant.dart';
import '../admin/verify.dart'; // เพิ่มการ import หน้า admin (สร้างหน้านี้ตามต้องการ)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oura Restaurant Reservation App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8B2323),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF8B2323),
          secondary: const Color(0xFF8B2323),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthCheckPage(),
    );
  }
}

class AuthCheckPage extends StatelessWidget {
  AuthCheckPage({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Widget> _getStartupScreen() async {
    User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      // ถ้ายังไม่ได้ล็อกอิน ส่งไปหน้า WelcomePage
      return const WelcomePage();
    }
    
    try {
      // ตรวจสอบว่าเป็น admin หรือไม่
      DocumentSnapshot adminDoc = await _firestore
          .collection('admins')
          .doc(currentUser.uid)
          .get();
      
      if (adminDoc.exists) {
        return const AdminPanel();
      }
      
      // ตรวจสอบว่าเป็น partner หรือไม่
      DocumentSnapshot partnerDoc = await _firestore
          .collection('partners')
          .doc(currentUser.uid)
          .get();
      
      if (partnerDoc.exists) {
        Map<String, dynamic> partnerData = partnerDoc.data() as Map<String, dynamic>;
        
        // ตรวจสอบว่า partner ได้สร้างร้านอาหารไปแล้วหรือไม่
        if (partnerData.containsKey('hasSubmittedRestaurant') && 
            partnerData['hasSubmittedRestaurant'] == true) {
          // กรณีที่สร้างร้านอาหารไปแล้ว ส่งไปหน้า ThankYouPage
          return const ThankYouPage();
        } else {
          // กรณีที่ยังไม่ได้สร้างร้านอาหาร ส่งไปหน้าสร้างร้านอาหาร
          return const CreateRestaurantPage();
        }
      }
      
      // ตรวจสอบว่าเป็น user หรือไม่
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        return const QuraApp();
      }
    } catch (e) {
      print('Error checking user type: $e');
    }
    
    // กรณีเกิดข้อผิดพลาดหรือไม่พบข้อมูลผู้ใช้ ให้ส่งไปหน้า WelcomePage
    return const WelcomePage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartupScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2323)),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return snapshot.data ?? const WelcomePage();
        }
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Oura',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B2323),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Oura Restaurant Reservation App',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF8B2323),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2323),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B2323)),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8B2323),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This class can be your home page for users after successful login
class HomePage extends StatefulWidget {
  final String userRole;
  const HomePage({super.key, required this.userRole});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  void _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oura App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Oura!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'You are logged in as: ${widget.userRole}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _signOut,
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}