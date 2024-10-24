import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'patient_profile_details.dart';
import 'patient_chat_diet.dart';
import 'patient_chat_trainer.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  String? userName;
  bool isLoading = true;
  int unreadMessagesCount = 0; // For counting unread messages

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
          userName = snapshot.docs.first['name'];
          isLoading = false;
        });
        _fetchUnreadMessagesCount(
            snapshot.docs.first.id); // Fetch unread messages
      } else {
        setState(() {
          userName = "User not found";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUnreadMessagesCount(String patientId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(patientId)
        .collection('messages')
        .where('isRead', isEqualTo: false) // Count unread messages
        .get();

    setState(() {
      unreadMessagesCount = snapshot.docs.length; // Update the count
    });
  }

  void _startChatWithDietician() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final patientId = snapshot.docs.first.id;

        // Navigate to PatientChatDiet instead of DieticianChatPatient
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientChatDiet(patientId: patientId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Profile"),
        backgroundColor: const Color.fromARGB(255, 70, 206, 227),
        automaticallyImplyLeading: false,
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
          Container(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const SizedBox.shrink()
                : Text(
                    'Welcome, ${userName ?? 'Guest'}!',
                    style: const TextStyle(fontSize: 24),
                  ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Chat with your Dietician"),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      FloatingActionButton(
                        onPressed: _startChatWithDietician,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.chat),
                      ),
                      if (unreadMessagesCount >
                          0) // Show badge if there are unread messages
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadMessagesCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Chat with your Trainer"),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientChatTrainer(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.chat),
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
