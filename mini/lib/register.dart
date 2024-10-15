import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  bool _showProgress = false;
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Updated roles
  List<String> roles = ['Patient', 'Dietician', 'Trainer'];
  String selectedRole = 'Select Role'; // Default value

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 19, 3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color.fromARGB(255, 91, 181, 219),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      const Text(
                        "Register Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: _isPasswordObscure,
                        suffixIcon:
                            _togglePasswordVisibility(isConfirmPassword: false),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: confirmPasswordController,
                        hintText: 'Confirm Password',
                        obscureText: _isConfirmPasswordObscure,
                        suffixIcon:
                            _togglePasswordVisibility(isConfirmPassword: true),
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleDropdown(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      validator: validator,
    );
  }

  Widget _togglePasswordVisibility({required bool isConfirmPassword}) {
    return IconButton(
      icon: Icon(isConfirmPassword
          ? _isConfirmPasswordObscure
              ? Icons.visibility_off
              : Icons.visibility
          : _isPasswordObscure
              ? Icons.visibility_off
              : Icons.visibility),
      onPressed: () {
        setState(() {
          if (isConfirmPassword) {
            _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
          } else {
            _isPasswordObscure = !_isPasswordObscure;
          }
        });
      },
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Display the selected role or "Select Role" if none is selected
          Text(
            selectedRole == 'Select Role' ? 'Select Role' : selectedRole,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: selectedRole == 'Select Role' ? Colors.grey : Colors.black,
            ),
          ),
          DropdownButton<String>(
            dropdownColor: Color.fromARGB(255, 85, 86, 87),
            value: selectedRole,
            underline: SizedBox(), // Remove underline
            items: [
              ...['Select Role'],
              ...roles
            ].map((String role) {
              return DropdownMenuItem(
                value: role,
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedRole = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Login", style: TextStyle(fontSize: 20)),
        ),
        ElevatedButton(
          onPressed: _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Register", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value!.isEmpty) {
      return "Email cannot be empty";
    }
    if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$').hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value!.isEmpty) {
      return "Password cannot be empty";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters long";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  void _register() async {
    if (_formKey.currentState!.validate() && selectedRole != 'Select Role') {
      setState(() {
        _showProgress = true;
      });
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        await _postDetailsToFirestore(userCredential.user!.uid);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          _showProgress = false;
        });
      }
    } else {
      // Handle the case where no role is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
    }
  }

  Future<void> _postDetailsToFirestore(String uid) async {
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    CollectionReference users = firebaseFirestore.collection('users');

    await users.doc(uid).set({
      'email': emailController.text,
      'role': selectedRole,
    });
  }
}
