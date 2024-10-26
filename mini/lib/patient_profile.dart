import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  Map<String, dynamic>? assignedDiet;
  DateTime? dietAssignedAt;

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
        _fetchUnreadMessagesCount(snapshot.docs.first.id);
        _fetchAssignedDiet(snapshot.docs.first.id);
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
        .where('patientId', isEqualTo: patientId) // Count unread messages
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      unreadMessagesCount = snapshot.docs.length; // Update the count
    });
  }

  Future<void> _fetchAssignedDiet(String patientId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .get();

    if (snapshot.exists) {
      final dietRef = snapshot.data()?['dietRef'] as String?;

      if (dietRef != null) {
        final dietSnapshot = await FirebaseFirestore.instance
            .collection('food')
            .doc(dietRef)
            .get();

        if (dietSnapshot.exists) {
          setState(() {
            assignedDiet = dietSnapshot.data();
            dietAssignedAt = snapshot.data()?['dietAssignedAt']?.toDate();
          });
        }
      }
    }
  }

  bool isDietVisible() {
    if (dietAssignedAt == null) return false;
    return DateTime.now().isBefore(dietAssignedAt!.add(Duration(hours: 24)));
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientChatDiet(patientId: patientId),
          ),
        );
      }
    }
  }

  void _startChatWithTrainer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final patientId = snapshot.docs.first.id;
        final patientName = snapshot.docs.first['name'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientChatTrainer(
              patientId: patientId,
              patientName: patientName,
              trainerName:
                  "Your Trainer Name", // Replace with actual trainer's name
            ),
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
          if (isDietVisible() && assignedDiet != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Assigned Diet:',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Breakfast: ${assignedDiet!['breakfast'].join(', ')}'),
                      Text('Lunch: ${assignedDiet!['lunch'].join(', ')}'),
                      Text('Dinner: ${assignedDiet!['dinner'].join(', ')}'),
                      Text('Snacks: ${assignedDiet!['snacks'].join(', ')}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                      if (unreadMessagesCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              '$unreadMessagesCount',
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
                    onPressed: _startChatWithTrainer,
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
}
