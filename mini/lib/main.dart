import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage
//import 'register.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set to false
      title: 'Diet and Workout',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // Set LoginPage as the home page
    );
  }
}
