import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool isUser = true;
  final _formKey = GlobalKey<FormState>();

  // Common controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // User specific controllers
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  
  // Partner specific controllers
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();
  final TextEditingController _restaurantNameController = TextEditingController();

  void _clearFormFields() {
    // Clear common fields
    _emailController.clear();
    _passwordController.clear();
    
    // Clear user specific fields
    _userNameController.clear();
    _userPhoneController.clear();
    
    // Clear partner specific fields
    _partnerNameController.clear();
    _partnerPhoneController.clear();
    _restaurantNameController.clear();
    
    _formKey.currentState?.reset();
  }

  // ฟังก์ชันสำหรับสร้างผู้ใช้ใหม่ใน Users collection และเพิ่ม coins เริ่มต้น
  Future<void> _createUserWithCoins(String uid, Map<String, dynamic> userData) async {
    try {
      // เพิ่มฟิลด์ coins ตั้งค่าเริ่มต้นที่ 10
      userData['coins'] = 10;
      
      // บันทึกข้อมูลผู้ใช้ลงใน Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
      
      print("✅ User data saved with 10 initial coins!");
      
      // บันทึกประวัติการได้รับ coins ใน subcollection (ถ้าต้องการ)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('coinsHistory')
          .add({
            'amount': 10,
            'type': 'credit',
            'reason': 'Welcome bonus',
            'timestamp': Timestamp.now(),
          });
          
      print("✅ Initial coins history recorded!");
    } catch (e) {
      print("❌ Error creating user with coins: $e");
      throw e; // ส่งต่อ error เพื่อให้ฟังก์ชันที่เรียกใช้จัดการต่อไป
    }
  }
  
  // ฟังก์ชันเพิ่ม coins ให้กับผู้ใช้ (สำหรับใช้ในอนาคต)
  Future<void> _addCoinsToUser(String userId, int amount) async {
    if (amount <= 0) return; // ไม่เพิ่มถ้าจำนวนไม่ถูกต้อง
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'coins': FieldValue.increment(amount),
          });
      
      // บันทึกประวัติการเพิ่ม coins
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('coinsHistory')
          .add({
            'amount': amount,
            'type': 'credit',
            'reason': 'System reward',
            'timestamp': Timestamp.now(),
          });
          
    } catch (e) {
      print('Error adding coins to user: $e');
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      print("✅ Form validation passed, proceeding with Firebase registration...");
      
      try {
        print("🔄 Creating Firebase user...");
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        print("✅ Firebase Auth Success, UID: ${userCredential.user?.uid}");

        String uid = userCredential.user!.uid;

        print("🔄 Saving user data to Firestore...");
        
        if (isUser) {
          // เตรียมข้อมูลผู้ใช้
          Map<String, dynamic> userData = {
            'uid': uid,
            'name': _userNameController.text,
            'phone': _userPhoneController.text,
            'email': _emailController.text,
            'role': "User",
            'createdAt': Timestamp.now(),
          };
          
          // สร้างผู้ใช้พร้อมกับ coins เริ่มต้น
          await _createUserWithCoins(uid, userData);
          print("✅ User data saved with initial coins successfully in Firestore!");
        } else {
          // Save Partner data (ไม่มี coins)
          await FirebaseFirestore.instance.collection('partners').doc(uid).set({
            'uid': uid,
            'ownerName': _partnerNameController.text,
            'phone': _partnerPhoneController.text,
            'email': _emailController.text,
            'role': "Partner",
            'createdAt': Timestamp.now(),
            'restaurantName': _restaurantNameController.text,
            'isVerified': false,
          });
          print("✅ Partner data saved successfully in Firestore!");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isUser ? "User" : "Partner"} Registered Successfully!')),
        );
        
        // Navigate back to login page
        Navigator.pop(context);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // User/Partner Tab
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleTab('User', true),
                  const SizedBox(width: 40),
                  _buildRoleTab('Partner', false),
                ],
              ),
              const SizedBox(height: 30),

              if (isUser) _buildUserForm(),
              if (!isUser) _buildPartnerForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String title, bool isUserTab) {
    final bool isSelected = (isUserTab && isUser) || (!isUserTab && !isUser);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          isUser = isUserTab;
          _clearFormFields();
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 120,
            height: 2,
            color: isSelected ? const Color(0xFF8B2323) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Full Name', _userNameController),
            const SizedBox(height: 15),
            _buildTextField('Phone Number', _userPhoneController),
            const SizedBox(height: 15),
            _buildTextField('E-Mail', _emailController),
            const SizedBox(height: 15),
            _buildTextField('Password', _passwordController, isPassword: true),
            const SizedBox(height: 15),
            // ข้อความแสดงโบนัส coins เริ่มต้น
            const Text(
              '* New users get 10 coins as a welcome bonus! 🎁',
              style: TextStyle(
                color: Color(0xFF8B2323),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
    
            _buildRegisterButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerForm() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Owner Name', _partnerNameController),
            const SizedBox(height: 15),
            _buildTextField('Contact Phone', _partnerPhoneController),
            const SizedBox(height: 15),
            _buildTextField('Restaurant Name', _restaurantNameController),
            const SizedBox(height: 15),
            _buildTextField('E-Mail', _emailController),
            const SizedBox(height: 15),
            _buildTextField('Password', _passwordController, isPassword: true),
            const SizedBox(height: 30),
    
            _buildRegisterButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B2323),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          'Register',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w500
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: (value) {
            if (value == null || value.isEmpty) return 'This field cannot be empty';
            if (label == 'E-Mail' && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Invalid email format';
            }
            if ((label == 'Phone Number' || label == 'Contact Phone') && !RegExp(r'^\d{10}$').hasMatch(value)) {
              return 'Phone number must be 10 digits';
            }
            if (label == 'Password' && value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF8B2323), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF8B2323), width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}