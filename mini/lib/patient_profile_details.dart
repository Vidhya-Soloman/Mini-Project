import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart'; // Import your login page
import 'patient_profile.dart';

class PatientProfileDetails extends StatefulWidget {
  const PatientProfileDetails({super.key});

  @override
  State<PatientProfileDetails> createState() => _PatientProfileDetailsState();
}

class _PatientProfileDetailsState extends State<PatientProfileDetails> {
  Map<String, dynamic>? patientData;
  bool isLoading = true;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController medicalConditionController =
      TextEditingController();
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchPatientDetails();
  }

  Future<void> fetchPatientDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('patients')
            .where('email', isEqualTo: email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          userId = snapshot.docs.first.id;
          setState(() {
            patientData = snapshot.docs.first.data();
            isLoading = false;

            // Populate controllers with current values
            ageController.text = patientData!['age'].toString();
            weightController.text = patientData!['weight'].toString();
            heightController.text = patientData!['height'].toString();
            medicalConditionController.text =
                patientData!['medicalCondition'] ?? '';
          });
        } else {
          setState(() {
            patientData = null;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching patient details: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updatePatientDetails() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('patients').doc(userId).set({
        'age': int.tryParse(ageController.text) ?? patientData!['age'],
        'weight':
            double.tryParse(weightController.text) ?? patientData!['weight'],
        'height':
            double.tryParse(heightController.text) ?? patientData!['height'],
        'medicalCondition': medicalConditionController.text.isNotEmpty
            ? medicalConditionController.text
            : patientData!['medicalCondition'],
      }, SetOptions(merge: true));

      setState(() {
        patientData!['age'] = int.tryParse(ageController.text);
        patientData!['weight'] = double.tryParse(weightController.text);
        patientData!['height'] = double.tryParse(heightController.text);
        patientData!['medicalCondition'] =
            medicalConditionController.text.isNotEmpty
                ? medicalConditionController.text
                : patientData!['medicalCondition'];
        isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color.fromARGB(255, 228, 218, 234),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientProfile()),
            );
          },
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 190, 214, 237),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : patientData != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailCard(
                                  "Name", patientData!['name'] ?? 'N/A'),
                              _buildDetailCard(
                                  "Email", patientData!['email'] ?? 'N/A'),
                              _buildEditableCard(
                                  "Age", ageController, isEditing),
                              _buildEditableCard(
                                  "Weight", weightController, isEditing),
                              _buildEditableCard(
                                  "Height", heightController, isEditing),
                              _buildEditableCard("Medical Condition",
                                  medicalConditionController, isEditing),
                              const SizedBox(height: 20),
                              if (patientData?['weight'] != null &&
                                  patientData?['height'] != null) ...[
                                Text(
                                  "BMI: ${calculateBMI(patientData!['weight'], patientData!['height'])?.toStringAsFixed(2) ?? 'N/A'}",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Health Status: ${getHealthStatus(calculateBMI(patientData!['weight'], patientData!['height'])!)}",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: getHealthStatus(calculateBMI(
                                                patientData!['weight'],
                                                patientData!['height'])!) ==
                                            "Healthy weight"
                                        ? const Color.fromARGB(255, 43, 149, 46)
                                        : Colors.red,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isEditing) {
                                      updatePatientDetails();
                                    } else {
                                      setState(() {
                                        isEditing = true;
                                        medicalConditionController.text =
                                            patientData!['medicalCondition'] ??
                                                '';
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 70, 206, 227),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isEditing ? "Save" : "Edit",
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    bool? confirm = await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm Sign Out"),
                                          content: const Text(
                                              "Are you sure you want to sign out?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text("Sign Out"),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage()), // Navigate to Login page
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Sign Out",
                                      style: TextStyle(fontSize: 18)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text("No patient details found",
                        style: TextStyle(fontSize: 20)),
                  ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Flexible(child: Text(value, style: const TextStyle(fontSize: 18))),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableCard(
      String label, TextEditingController controller, bool isEditing) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            isEditing
                ? Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: label == "Medical Condition"
                          ? TextInputType.text
                          : TextInputType.number,
                      decoration: InputDecoration(
                          hintText: label, border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a valid $label';
                        }
                        return null;
                      },
                    ),
                  )
                : Text(controller.text, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  double? calculateBMI(double weight, double height) {
    return weight / ((height / 100) * (height / 100));
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
}
