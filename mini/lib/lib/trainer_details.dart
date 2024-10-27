import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'trainer_profile.dart'; // Import the TrainerProfile widget
import 'trainer_chat_patient.dart'; // Import the TrainerChatPatient widget
import 'assign_workout.dart'; // Import the AssignWorkout widget
import 'package:firebase_auth/firebase_auth.dart';

class TrainerDetails extends StatefulWidget {
  const TrainerDetails({super.key});

  @override
  _TrainerDetailsState createState() => _TrainerDetailsState();
}

class _TrainerDetailsState extends State<TrainerDetails> {
  void _onWorkoutAssigned() {
    // This function will be called when a workout is assigned.
    // You can perform any actions here, like refreshing data or showing a message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout assigned successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trainers')
                  .doc(user
                      ?.uid) // Assuming the trainer's document ID is their UID
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No trainer details found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final trainerName = data['name'] ?? "Trainer";

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Hello, $trainerName!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Patients:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text("No patients found."));
                            }

                            final patients = snapshot.data!.docs.map((doc) {
                              double bmi = doc['bmi'] is double
                                  ? doc['bmi']
                                  : double.tryParse(doc['bmi'].toString()) ??
                                      0.0;
                              return {
                                'id': doc.id,
                                'name': doc['name'] ?? 'Unknown',
                                'medicalCondition':
                                    doc['medicalCondition'] ?? 'N/A',
                                'bmi': bmi.toStringAsFixed(2),
                                'age': doc['age'] ?? 'N/A',
                                'gender': doc['gender'] ?? 'N/A',
                              };
                            }).toList();

                            return ListView.builder(
                              itemCount: patients.length,
                              itemBuilder: (context, index) {
                                final patient = patients[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(patient['name']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Medical Condition: ${patient['medicalCondition']}'),
                                        Text('Age: ${patient['age']}'),
                                        Text('BMI: ${patient['bmi']}'),
                                        Text('Gender: ${patient['gender']}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chat),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('trainers')
                                                .doc(user?.uid)
                                                .get()
                                                .then((trainerSnapshot) {
                                              final trainerName =
                                                  trainerSnapshot
                                                          .data()?['name'] ??
                                                      'Trainer';
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TrainerChatPatient(
                                                    patientId: patient['id'],
                                                    patientName:
                                                        patient['name'],
                                                    trainerName: trainerName,
                                                  ),
                                                ),
                                              );
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons
                                              .fitness_center), // Exercise icon
                                          onPressed: () {
                                            // Navigate to AssignWorkout with the selected patient's details
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AssignWorkout(
                                                  patientId: patient['id'],
                                                  onWorkoutAssigned:
                                                      _onWorkoutAssigned, // Pass the callback
                                                ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
