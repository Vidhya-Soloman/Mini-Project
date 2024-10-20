import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dietician_profile.dart'; // Import the profile page
import 'dietician_chat_patient.dart'; // Import the chat page

class DieticianDetails extends StatefulWidget {
  const DieticianDetails({super.key});

  @override
  State<DieticianDetails> createState() => _DieticianDetailsState();
}

class _DieticianDetailsState extends State<DieticianDetails> {
  Map<String, dynamic>? dieticianDetails; // Variable to store dietician details
  List<Map<String, dynamic>> patients = []; // List to store patient data
  List<bool> checkedPatients = []; // List to track checkbox states
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchDieticianDetails(); // Fetch the dietician's details on init
    _fetchPatientData(); // Fetch the patient data on init
  }

  Future<void> _fetchDieticianDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch dietician details from Firestore using the user's email
      var dieticianSnapshot = await FirebaseFirestore.instance
          .collection('dieticians')
          .where('email', isEqualTo: user.email) // Query by email
          .get();

      if (dieticianSnapshot.docs.isNotEmpty) {
        setState(() {
          dieticianDetails =
              dieticianSnapshot.docs.first.data(); // Fetching the details
        });
      }
    }
    setState(() {
      isLoading = false; // Update loading state
    });
  }

  Future<void> _fetchPatientData() async {
    try {
      var patientSnapshot =
          await FirebaseFirestore.instance.collection('patients').get();

      setState(() {
        patients = patientSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'], // Assuming there's a 'name' field
            'bmi': doc['bmi'], // Assuming there's a 'bmi' field
            'medicalCondition': doc[
                'medicalCondition'], // Assuming there's a 'medicalCondition' field
          };
        }).toList();

        // Initialize the checkbox state for each patient
        checkedPatients = List<bool>.filled(patients.length, false);
      });
    } catch (e) {
      print('Error fetching patient data: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Sign out the user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(), // Navigate back to login page
      ),
    );
  }

  void _startConversation() {
    // Find the first selected patient's ID
    int selectedIndex = checkedPatients.indexOf(true);
    if (selectedIndex != -1) {
      String patientId = patients[selectedIndex]['id'];

      // Navigate to the chat page with the selected patient ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DieticianChatPatient(
              patientId: patientId), // Pass single patient ID
        ),
      );
    } else {
      // Optionally show an alert if no patients are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a patient to chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
            255, 100, 150, 250), // Change to your desired color
        title: const Text("Dietician"),
        automaticallyImplyLeading: false, // Remove back icon
        actions: [
          IconButton(
            icon: const Icon(Icons.person), // Profile icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DieticianProfile(), // Navigate to profile page
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align to the left
                children: [
                  Text(
                    dieticianDetails?['name'] != null
                        ? "Welcome, ${dieticianDetails!['name']}!" // Personalized welcome message
                        : "Welcome!", // Default message if name is not found
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20), // Add some spacing
                  const Text(
                    "Patients:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10), // Add some spacing
                  Expanded(
                    child: ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(patients[index]['name']),
                            subtitle: Text(
                              'BMI: ${patients[index]['bmi']}\nMedical Condition: ${patients[index]['medicalCondition']}',
                            ),
                            trailing: Checkbox(
                              value: checkedPatients[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  checkedPatients[index] =
                                      value ?? false; // Update checkbox state
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _startConversation,
                    child: const Text("Start Conversation"),
                  ),
                ],
              ),
            ),
    );
  }
}
