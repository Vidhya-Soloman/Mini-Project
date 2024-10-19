import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';
import 'patient_profile_details.dart'; // Import the details page

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
        backgroundColor: Color.fromARGB(
            255, 70, 206, 227), // Set the desired background color
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Text(
                'Welcome, ${userName ?? 'Guest'}!',
                style: TextStyle(fontSize: 24),
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
