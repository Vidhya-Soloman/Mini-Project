import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dietician_profile.dart';
import 'dietician_chat_patient.dart';
import 'assign_diet.dart';

class DieticianDetails extends StatefulWidget {
  const DieticianDetails({super.key});

  @override
  State<DieticianDetails> createState() => _DieticianDetailsState();
}

class _DieticianDetailsState extends State<DieticianDetails> {
  Map<String, dynamic>? dieticianDetails;
  bool isLoading = true;
  Map<String, DateTime> assignedPatients = {}; // Track assigned diets with time

  @override
  void initState() {
    super.initState();
    _fetchDieticianDetails();
  }

  Future<void> _fetchDieticianDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var dieticianSnapshot = await FirebaseFirestore.instance
          .collection('dieticians')
          .where('email', isEqualTo: user.email)
          .get();

      if (dieticianSnapshot.docs.isNotEmpty) {
        setState(() {
          dieticianDetails = dieticianSnapshot.docs.first.data();
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Callback function to update assigned diet status
  void _onDietAssigned(String patientId) {
    setState(() {
      assignedPatients[patientId] = DateTime.now(); // Store the current time
    });
  }

  bool _isDietAssignedRecently(String patientId) {
    if (!assignedPatients.containsKey(patientId)) return false;

    DateTime assignmentTime = assignedPatients[patientId]!;
    return DateTime.now().difference(assignmentTime).inHours <
        24; // Check if within 24 hours
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 100, 150, 250),
        title: const Text("Dietician"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DieticianProfile(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dieticianDetails?['name'] != null
                        ? "Welcome, ${dieticianDetails!['name']}!"
                        : "Welcome!",
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Patients:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('patients')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        final patients = snapshot.data!.docs.map((doc) {
                          return {
                            'id': doc.id,
                            'name': doc['name'],
                            'medicalCondition': doc['medicalCondition'],
                            'age': doc['age'],
                            'bmi': doc['bmi'],
                            'gender': doc['gender'],
                          };
                        }).toList();

                        return ListView.builder(
                          itemCount: patients.length,
                          itemBuilder: (context, index) {
                            String patientId = patients[index]['id'];
                            bool isDietAssigned =
                                _isDietAssignedRecently(patientId);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                title: Text(patients[index]['name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Medical Condition: ${patients[index]['medicalCondition']}'),
                                    Text('Age: ${patients[index]['age']}'),
                                    Text(
                                        'BMI: ${patients[index]['bmi']?.toStringAsFixed(2) ?? 'N/A'}'),
                                    Text(
                                        'Gender: ${patients[index]['gender'] ?? 'N/A'}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chat),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DieticianChatPatient(
                                              patientId: patientId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.restaurant_menu,
                                        color: isDietAssigned
                                            ? Colors
                                                .green // Change color if diet is assigned
                                            : null, // Default color
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AssignDiet(
                                                patientId: patientId,
                                                onDietAssigned: () =>
                                                    _onDietAssigned(
                                                        patientId)), // Pass the callback
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
