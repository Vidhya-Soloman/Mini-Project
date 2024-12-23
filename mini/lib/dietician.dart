import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
import 'dietician_details.dart'; // Import the details page

class Dietician extends StatefulWidget {
  const Dietician({super.key});

  @override
  State<Dietician> createState() => _DieticianState();
}

class _DieticianState extends State<Dietician> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? age;
  String? qualification;
  String? phoneNumber; // New field for phone number
  String? specialization; // New field for specialization
  String? experience; // New field for experience

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dietician"),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                onSaved: (value) {
                  name = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Age field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  age = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Qualification field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Qualification',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                onSaved: (value) {
                  qualification = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your qualification';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Phone Number field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  phoneNumber = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Specialization field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                onSaved: (value) {
                  specialization = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your specialization';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Experience field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Experience (in years)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  experience = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // Fetch the current user's email from the 'users' collection
                    final user = FirebaseAuth.instance.currentUser;
                    String? userEmail;

                    if (user != null) {
                      final userSnapshot = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();

                      if (userSnapshot.exists) {
                        userEmail = userSnapshot.data()?['email'];
                      }
                    }

                    // Save the details to Firestore under the 'dieticians' collection
                    await FirebaseFirestore.instance
                        .collection('dieticians')
                        .add({
                      'name': name,
                      'email': userEmail, // Save the fetched email
                      'age': age,
                      'qualification': qualification,
                      'phoneNumber': phoneNumber, // Save phone number
                      'specialization': specialization, // Save specialization
                      'experience': experience, // Save experience
                    });

                    // Show a snackbar to confirm submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Details submitted successfully!',
                        ),
                      ),
                    );

                    // Navigate to the dietician details page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DieticianDetails(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Background color
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }
}
