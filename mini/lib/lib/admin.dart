import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> fetchedUsers = [];

      for (var doc in querySnapshot.docs) {
        fetchedUsers.add({
          'id': doc.id,
          'email': doc['email'], // Assuming there is an 'email' field
          'role': doc['role'], // Assuming there is a 'role' field
        });
      }

      setState(() {
        users = fetchedUsers;
      });
    } catch (e) {
      print("Error fetching users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch users")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete from the 'users' collection
      await _firestore.collection('users').doc(userId).delete();

      // Delete from the 'patients' collection
      await _firestore.collection('patients').doc(userId).delete();

      // Delete associated workouts
      final workoutsSnapshot = await _firestore
          .collection('workouts')
          .where('patientId', isEqualTo: userId)
          .get();
      for (var workoutDoc in workoutsSnapshot.docs) {
        await workoutDoc.reference.delete();
      }

      // Delete associated food records
      final foodSnapshot = await _firestore
          .collection('food')
          .where('patientId', isEqualTo: userId)
          .get();
      for (var foodDoc in foodSnapshot.docs) {
        await foodDoc.reference.delete();
      }

      setState(() {
        users.removeWhere((user) => user['id'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User and associated data deleted successfully")),
      );
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete user")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grouping users by role
    Map<String, List<Map<String, dynamic>>> groupedUsers = {
      'Patients': [],
      'Dieticians': [],
      'Trainers': [],
    };

    for (var user in users) {
      if (user['role'] == 'Patient') {
        groupedUsers['Patients']!.add(user);
      } else if (user['role'] == 'Dietician') {
        groupedUsers['Dieticians']!.add(user);
      } else if (user['role'] == 'Trainer') {
        groupedUsers['Trainers']!.add(user);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin"),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: groupedUsers.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...entry.value.map((user) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(user['email']),
                          subtitle: Text(user['role']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Confirm deletion
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Deletion"),
                                    content: const Text(
                                        "Are you sure you want to delete this user? This will also delete all associated data."),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Cancel
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          deleteUser(user['id']);
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
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
