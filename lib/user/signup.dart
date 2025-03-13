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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _clearFormFields() {
  _emailController.clear();
  _phoneController.clear();
  _nameController.clear();
  _passwordController.clear();
  _formKey.currentState?.reset();
}


  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      String role = isUser ? "users" : "partners"; 
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
await FirebaseFirestore.instance.collection(role).doc(uid).set({
  'uid': uid,
  'name': _nameController.text,
  'phone': _phoneController.text,
  'email': _emailController.text,
  'role': isUser ? "User" : "Partner",
  'createdAt': Timestamp.now(),
});
print("✅ User data saved successfully in Firestore!");


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$role Registered Successfully!')),
        );
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
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

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

  Widget _buildRoleTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isUser != isSelected) {
          setState(() {
            isUser = isSelected;
            _clearFormFields();
          });
        }
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
          if (isSelected)
            Container(
              width: 50,
              height: 2,
              color: const Color(0xFF8B2323),
            ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Name', _nameController),
        const SizedBox(height: 15),
        _buildTextField('Phone Number', _phoneController),
        const SizedBox(height: 15),
        _buildTextField('E-Mail', _emailController),
        const SizedBox(height: 15),
        _buildTextField('Password', _passwordController, isPassword: true),
        const SizedBox(height: 30),

        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildPartnerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Full Name', _nameController),
        const SizedBox(height: 15),
        _buildTextField('Phone Number', _phoneController),
        const SizedBox(height: 15),
        _buildTextField('E-Mail', _emailController),
        const SizedBox(height: 15),
        _buildTextField('Password', _passwordController, isPassword: true),
        const SizedBox(height: 30),

        _buildRegisterButton(
          
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Center(
      child: ElevatedButton(
        
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B2323),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 120),
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
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: (value) {
            if (value == null || value.isEmpty) return 'This field cannot be empty';
            if (label == 'E-Mail' && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Invalid email format';
            }
            if (label == 'Phone Number' && !RegExp(r'^\d{10}$').hasMatch(value)) {
              return 'Phone number must be 10 digits';
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF8B2323), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
