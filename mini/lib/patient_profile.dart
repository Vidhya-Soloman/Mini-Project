import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
import 'patient_profile_details.dart'; // Import the details page
import 'patient_chat_diet.dart'; // Import your dietician chat page
import 'patient_chat_trainer.dart'; // Import your trainer chat page

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          userName = snapshot
              .docs.first['name']; // Adjust based on your Firestore structure
          isLoading = false;
        });
      } else {
        setState(() {
          userName = "User not found"; // Handle case where user isn't found
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false; // Handle case where there's no logged-in user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Profile"),
        backgroundColor: const Color.fromARGB(255, 70, 206, 227),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientProfileDetails(),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message at the top
          Container(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const SizedBox.shrink() // Do not display if loading
                : Text(
                    'Welcome, ${userName ?? 'Guest'}!',
                    style: const TextStyle(fontSize: 24),
                  ),
          ),
          // Display loading indicator or an empty space below
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(), // Empty space when not loading
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight, // Move to the right side
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dietician chat button with text
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                children: [
                  const Text("Chat with your Dietician"),
                  const SizedBox(width: 8), // Spacing between text and button
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PatientChatDiet(), // Navigate to the dietician chat page
                        ),
                      );
                    },
                    child: const Icon(Icons.chat),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16), // Spacing between the buttons
              // Trainer chat button with text
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                children: [
                  const Text("Chat with your Trainer"),
                  const SizedBox(width: 8), // Spacing between text and button
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PatientChatTrainer(), // Navigate to the trainer chat page
                        ),
                      );
                    },
                    child: const Icon(Icons
                        .chat), // You might want to change the icon to differentiate
                    backgroundColor:
                        Colors.blue, // Different color for the trainer chat
                  ),
                ],
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
