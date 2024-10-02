import 'package:flutter/material.dart';
import 'package:mini/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration Form',
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String age = '';
  String gender = 'Male';
  String height = '';
  String weight = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your name';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (value) => email = value,
                validator: (value) {
                  if (value!.isEmpty || !value.contains('@'))
                    return 'Please enter a valid email';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your password';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Retype Password'),
                obscureText: true,
                onChanged: (value) => confirmPassword = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please retype your password';
                  if (value != password) return 'Passwords do not match';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onChanged: (value) => age = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your age';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(labelText: 'Gender'),
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                items: <String>['Male', 'Female', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => height = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your height';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => weight = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your weight';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => phone = value,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your phone number';
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Process data (e.g., send to server)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registering...')),
                    );
                  }
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
