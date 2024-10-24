import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'trainer_profile.dart'; // Import the TrainerProfile widget
import 'package:firebase_auth/firebase_auth.dart';

class TrainerDetails extends StatelessWidget {
  const TrainerDetails({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    // Print the UID to check if it's valid
    print('User UID: ${user?.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trainer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        actions: [
          // Profile button to navigate to TrainerProfile
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainerProfile()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trainers')
            .doc(user?.uid) // Assuming the trainer's document ID is their UID
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if snapshot has data and the document exists
          print('Snapshot data: ${snapshot.data}');

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No trainer details found."));
          }

          // Fetching specific fields from the document
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final trainerName =
              data['name'] ?? "Trainer"; // Default name if not found

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Hello, $trainerName!",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
