import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Import your LoginPage

class DieticianProfile extends StatelessWidget {
  const DieticianProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 100, 150, 250),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile'));
          }
          final profileData = snapshot.data;

          return Container(
            color: const Color.fromARGB(255, 220, 240, 255),
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildProfileCard("Name", profileData?['name'] ?? 'N/A'),
                _buildProfileCard("Email", profileData?['email'] ?? 'N/A'),
                _buildProfileCard(
                    "Phone", profileData?['phoneNumber'] ?? 'N/A'),
                _buildProfileCard(
                    "Specialization", profileData?['specialization'] ?? 'N/A'),
                _buildProfileCard("Experience",
                    "${profileData?['experience'] ?? 'N/A'} years"),
                const SizedBox(height: 20), // Add some spacing
                ElevatedButton(
                  onPressed: () => _signOut(context),
                  child: const Text(
                    "Sign Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Increased text size
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0), // Smaller padding
                    backgroundColor: Color.fromARGB(
                        255, 235, 96, 96), // Change color as needed
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginPage()), // Navigate to the LoginPage
    );
  }

  Future<Map<String, dynamic>?> _fetchProfileData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var dieticianSnapshot = await FirebaseFirestore.instance
          .collection('dieticians')
          .where('email', isEqualTo: user.email)
          .get();

      if (dieticianSnapshot.docs.isNotEmpty) {
        return dieticianSnapshot.docs.first.data();
      }
    }
    return null;
  }
}
