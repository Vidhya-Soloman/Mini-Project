import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class PatientProfileDetails extends StatefulWidget {
  const PatientProfileDetails({super.key});

  @override
  State<PatientProfileDetails> createState() => _PatientProfileDetailsState();
}

class _PatientProfileDetailsState extends State<PatientProfileDetails> {
  Map<String, dynamic>? patientData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientDetails();
  }

  Future<void> fetchPatientDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          patientData = snapshot.docs.first.data();
          isLoading = false;
        });

        // Calculate BMI
        double? bmi =
            calculateBMI(patientData!['weight'], patientData!['height']);

        // Update Firestore with the new BMI value
        await updateBMIInFirestore(snapshot.docs.first.id, bmi);
      } else {
        setState(() {
          patientData = null; // Handle case where user isn't found
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false; // Handle case where there's no logged-in user
      });
    }
  }

  Future<void> updateBMIInFirestore(String userId, double? bmi) async {
    if (bmi != null) {
      // Update the document with the new BMI field
      await FirebaseFirestore.instance.collection('patients').doc(userId).set(
          {'bmi': bmi},
          SetOptions(
              merge: true)); // Use merge to avoid overwriting existing fields
    }
  }

  double? calculateBMI(double weight, double height) {
    return weight / ((height / 100) * (height / 100)); // height in meters
  }

  String getHealthStatus(double bmi) {
    if (bmi < 18.5) {
      return "Underweight";
    } else if (bmi < 24.9) {
      return "Healthy weight";
    } else if (bmi < 29.9) {
      return "Overweight";
    } else {
      return "Obese";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Details"),
      ),
      body: Container(
        color:
            Color.fromARGB(255, 190, 214, 237), // Light blue background color
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : patientData != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Patient Details:",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildDetailCard(
                              "Name", patientData!['name'] ?? 'N/A'),
                          _buildDetailCard(
                              "Email", patientData!['email'] ?? 'N/A'),
                          _buildDetailCard(
                              "Age", patientData!['age']?.toString() ?? 'N/A'),
                          _buildDetailCard(
                              "Gender", patientData!['gender'] ?? 'N/A'),
                          _buildDetailCard("Weight",
                              '${patientData!['weight'] ?? 'N/A'} kg'),
                          _buildDetailCard("Height",
                              '${patientData!['height'] ?? 'N/A'} cm'),
                          SizedBox(height: 20),
                          // Calculate and display BMI and health status
                          if (patientData?['weight'] != null &&
                              patientData?['height'] != null) ...[
                            Text(
                              "BMI: ${calculateBMI(patientData!['weight'], patientData!['height'])?.toStringAsFixed(2) ?? 'N/A'}",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Health Status: ${getHealthStatus(calculateBMI(patientData!['weight'], patientData!['height'])!)}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: getHealthStatus(calculateBMI(
                                            patientData!['weight'],
                                            patientData!['height'])!) ==
                                        "Healthy weight"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle edit action here
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue, // Blue background color
                                foregroundColor:
                                    Colors.white, // White text color
                              ),
                              child: const Text("Edit",
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red, // Red background color
                                foregroundColor:
                                    Colors.white, // White text color
                              ),
                              child: const Text("Sign Out",
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text("No patient details found",
                        style: TextStyle(fontSize: 20))),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      elevation: 4,
      color: Colors.white, // Contrasting background color for detail cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
