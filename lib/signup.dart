import 'package:flutter/material.dart';

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
    _formKey.currentState?.reset();
    _emailController.clear();
    _phoneController.clear();
    _nameController.clear();
    _passwordController.clear();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegEx = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegEx.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  String? _validateRequiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
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
                  GestureDetector(
                    onTap: () {
                      if (!isUser) {
                        setState(() {
                          isUser = true;
                          _clearFormFields();
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          'User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isUser ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (isUser)
                          Container(
                            width: 50,
                            height: 2,
                            color: const Color(0xFF8B2323),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () {
                      if (isUser) {
                        setState(() {
                          isUser = false;
                          _clearFormFields(); 
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          'Partner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !isUser ? Colors.black : Colors.grey,
                          ),
                        ),
                        if (!isUser)
                          Container(
                            width: 70,
                            height: 2,
                            color: const Color(0xFF8B2323),
                          ),
                      ],
                    ),
                  ),
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

  Widget _buildUserForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Name', _nameController, _validateRequiredField),
        const SizedBox(height: 15),
        _buildTextField('Phone Number', _phoneController, _validatePhone),
        const SizedBox(height: 15),
        _buildTextField('E-Mail', _emailController, _validateEmail),
        const SizedBox(height: 15),
        _buildTextField('Password', _passwordController, _validateRequiredField, ),
        const SizedBox(height: 30),

        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildPartnerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Full Name', _nameController, _validateRequiredField),
        const SizedBox(height: 15),
        _buildTextField('Phone Number', _phoneController, _validatePhone),
        const SizedBox(height: 15),
        _buildTextField('E-Mail', _emailController, _validateEmail),
        const SizedBox(height: 15),
        _buildTextField('Password', _passwordController, _validateRequiredField, ),
        const SizedBox(height: 30),

        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful!')),
            );
          }
        },
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

  Widget _buildTextField(String label, TextEditingController controller, String? Function(String?)? validator, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: label == 'Phone Number' ? TextInputType.number : TextInputType.text,
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
