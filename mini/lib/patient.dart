import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class Patient extends StatefulWidget {
  const Patient({super.key});

  @override
  State<Patient> createState() => _PatientState();
}

class _PatientState extends State<Patient> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  int age = 0;
  String gender = 'Select'; // Default gender
  double height = 0.0;
  double weight = 0.0;
  String medicalCondition = '';
  List<Map<String, dynamic>> patientList = []; // To hold patient details

  @override
  void initState() {
    super.initState();
    fetchPatientData(); // Fetch initial data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient"),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Age',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        age = int.tryParse(value) ?? 0;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Select', child: Text('Select')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        gender = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value == 'Select') {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        height = double.tryParse(value) ?? 0.0;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your height';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        weight = double.tryParse(value) ?? 0.0;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your weight';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Medical Condition',
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        medicalCondition = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your medical condition';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        savePatientData();
                      }
                    },
                    child: const Text('Save Patient Details'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display the patient list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patientList.length,
              itemBuilder: (context, index) {
                final patient = patientList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Age: ${patient['age']}",
                            style: const TextStyle(fontSize: 16)),
                        Text("Gender: ${patient['gender']}",
                            style: const TextStyle(fontSize: 16)),
                        Text("Height: ${patient['height']} cm",
                            style: const TextStyle(fontSize: 16)),
                        Text("Weight: ${patient['weight']} kg",
                            style: const TextStyle(fontSize: 16)),
                        Text(
                            "Medical Condition: ${patient['medicalCondition']}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> savePatientData() async {
    try {
      // Save patient data to Firestore
      await _firestore.collection('patients').add({
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'medicalCondition': medicalCondition,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient details saved successfully")),
      );

      // Fetch updated patient data
      fetchPatientData();

      // Optionally, clear the form after saving
      _formKey.currentState?.reset();
      setState(() {
        gender = 'Select'; // Reset gender to default after saving
      });
    } catch (e) {
      print("Error saving patient data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save patient details")),
      );
    }
  }

  Future<void> fetchPatientData() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('patients').get();
      setState(() {
        patientList = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print("Error fetching patient data: $e");
    }
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
