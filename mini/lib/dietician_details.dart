import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class DieticianDetails extends StatefulWidget {
  const DieticianDetails({super.key});

  @override
  State<DieticianDetails> createState() => _DieticianDetailsState();
}

class _DieticianDetailsState extends State<DieticianDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dietician Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Dietician details will be displayed here.",
          style: TextStyle(fontSize: 18),
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
