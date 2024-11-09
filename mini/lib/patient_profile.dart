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
  int unreadMessagesCount = 0;
  Map<String, dynamic>? assignedDiet;
  DateTime? dietAssignedAt;
  List<Map<String, dynamic>>? assignedWorkouts;
  DateTime? workoutsAssignedAt;

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
        String patientId = snapshot.docs.first.id;
        _fetchUnreadMessagesCount(patientId);
        _fetchAssignedDiet(patientId);
        _fetchAssignedWorkouts(patientId);

        // Check if dietAssignedAt is older than 24 hours
        if (dietAssignedAt != null &&
            DateTime.now()
                .isAfter(dietAssignedAt!.add(const Duration(hours: 24)))) {
          _updateDietAssignmentStatus(patientId);
        }
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
        .where('patientId', isEqualTo: patientId)
        .where('isRead', isEqualTo: false)
        .get();

    setState(() {
      unreadMessagesCount = snapshot.docs.length;
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

  Future<void> _fetchAssignedWorkouts(String patientId) async {
    final workoutSnapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('patientId', isEqualTo: patientId)
        .get();

    if (workoutSnapshot.docs.isNotEmpty) {
      setState(() {
        assignedWorkouts = workoutSnapshot.docs
            .map((doc) => {
                  'core': doc.data()['core'] ?? [],
                  'upperBody': doc.data()['upperBody'] ?? [],
                  'lowerBody': doc.data()['lowerBody'] ?? [],
                  'cardio': doc.data()['cardio'] ?? [],
                  'assignedAt': doc.data()['assignedAt']?.toDate(),
                })
            .toList();
        workoutsAssignedAt = assignedWorkouts!.first['assignedAt'];
      });
    }
  }

  Future<void> _updateDietAssignmentStatus(String patientId) async {
    final patientDoc =
        FirebaseFirestore.instance.collection('patients').doc(patientId);

    // Update the dietAssigned field to false if 24 hours have passed
    await patientDoc.update({'dietAssigned': false});
  }

  bool isVisible(DateTime? assignedAt) {
    if (assignedAt == null) return false;
    return DateTime.now().isBefore(assignedAt.add(const Duration(hours: 24)));
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
              trainerName: "Your Trainer Name",
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
          if (isVisible(dietAssignedAt) &&
              assignedDiet != null &&
              assignedDiet!['dietAssigned'] != false) ...[
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
                      const Text(
                        'Your Assigned Diet:',
                        style: TextStyle(
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
          if (isVisible(workoutsAssignedAt) &&
              assignedWorkouts != null &&
              assignedWorkouts!.isNotEmpty) ...[
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
                      const Text(
                        'Your Assigned Workouts:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      for (var workout in assignedWorkouts!) ...[
                        if (workout['core'] != null &&
                            workout['core'].isNotEmpty)
                          Text('Core: ${workout['core'].join(', ')}'),
                        if (workout['upperBody'] != null &&
                            workout['upperBody'].isNotEmpty)
                          Text(
                              'Upper Body: ${workout['upperBody'].join(', ')}'),
                        if (workout['lowerBody'] != null &&
                            workout['lowerBody'].isNotEmpty)
                          Text(
                              'Lower Body: ${workout['lowerBody'].join(', ')}'),
                        if (workout['cardio'] != null &&
                            workout['cardio'].isNotEmpty)
                          Text('Cardio: ${workout['cardio'].join(', ')}'),
                        const SizedBox(height: 8),
                      ],
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
                            decoration: const BoxDecoration(
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
