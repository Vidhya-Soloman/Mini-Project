import 'package:flutter/material.dart';
//import 'login.dart';
import 'register.dart';

void main() {
  runApp(MyApp());
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blank Page')),
      body: Center(
        child: Text('This is a blank page', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
