import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignWorkout extends StatefulWidget {
  final String patientId;
  final Function onWorkoutAssigned; // Callback for workout assignment

  const AssignWorkout({
    super.key,
    required this.patientId,
    required this.onWorkoutAssigned,
  });

  @override
  _AssignWorkoutState createState() => _AssignWorkoutState();
}

class _AssignWorkoutState extends State<AssignWorkout> {
  final _formKey = GlobalKey<FormState>();
  List<String> selectedUpperBodyWorkouts = [];
  List<String> selectedLowerBodyWorkouts = [];
  List<String> selectedCoreWorkouts = [];
  List<String> selectedCardioWorkouts = [];

  final Map<String, List<String>> workoutOptions = {
    'Upper Body': [
      'Push-ups',
      'Dumbbell Bench Press',
      'Pull-ups',
      'Bicep Curls'
    ],
    'Lower Body': ['Squats', 'Lunges', 'Deadlifts', 'Calf Raises'],
    'Core': [
      'Plank',
      'Russian Twists',
      'Mountain Climbers',
      'Bicycle Crunches'
    ],
    'Cardio': ['Jumping Jacks', 'Burpees', 'High Knees', 'Jump Rope'],
  };

  String patientName = ''; // To hold the patient's name
  String patientEmail = ''; // To hold the patient's email
  String workoutStatus = 'Not Assigned'; // Initial status
  String? workoutDocumentId; // To hold the ID of the latest workout document

  @override
  void initState() {
    super.initState();
    _fetchPatientNameAndEmail();
    _fetchWorkoutStatus(); // Fetch existing workout status
  }

  Future<void> _fetchPatientNameAndEmail() async {
    try {
      final patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (patientSnapshot.exists) {
        setState(() {
          patientName =
              patientSnapshot.data()?['name'] ?? ''; // Fetch the patient's name
          patientEmail = patientSnapshot.data()?['email'] ??
              ''; // Fetch the patient's email
        });
      }
    } catch (e) {
      print('Error fetching patient information: $e');
    }
  }

  Future<void> _fetchWorkoutStatus() async {
    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('assignedAt', descending: true)
          .limit(1)
          .get();

      if (workoutSnapshot.docs.isNotEmpty) {
        final latestWorkout = workoutSnapshot.docs.first.data();
        workoutDocumentId =
            workoutSnapshot.docs.first.id; // Store the document ID

        // Check the latest status
        setState(() {
          workoutStatus = latestWorkout['status'] ??
              'Not Assigned'; // Update status from Firestore
        });

        print('Latest workout status: $workoutStatus'); // Debugging
      }
    } catch (e) {
      print('Error fetching workout status: $e');
    }
  }

  Future<void> _submitWorkout() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Prepare workout data to be saved or updated in workouts collection
      final workoutData = {
        'upperBody': selectedUpperBodyWorkouts,
        'lowerBody': selectedLowerBodyWorkouts,
        'core': selectedCoreWorkouts,
        'cardio': selectedCardioWorkouts,
        'assignedAt': Timestamp.now(),
        'patientId': widget.patientId, // Include patient ID for tracking
        'patientName': patientName, // Include patient name
        'patientEmail': patientEmail, // Include patient email for verification
        'status': 'Assigned', // Set status to 'Assigned'
      };

      try {
        if (workoutDocumentId != null) {
          // Update the existing document if it exists
          await FirebaseFirestore.instance
              .collection('workouts')
              .doc(workoutDocumentId)
              .update(workoutData);
        } else {
          // If no document exists, create a new one
          await FirebaseFirestore.instance
              .collection('workouts')
              .add(workoutData);
        }

        // Update the workout status in the UI
        setState(() {
          workoutStatus = 'Assigned'; // Update local status
        });

        // Log the workout data to check if it's saved correctly
        print('Workout data saved: $workoutData');

        // Notify the parent widget that the workouts have been assigned
        widget.onWorkoutAssigned();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workouts assigned successfully!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (error) {
        // Handle errors
        print('Error saving workout data: $error'); // Debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Widget _buildWorkoutSelection(String workoutType, List<String> workouts) {
    List<String> selectedWorkouts;
    switch (workoutType) {
      case 'Upper Body':
        selectedWorkouts = selectedUpperBodyWorkouts;
        break;
      case 'Lower Body':
        selectedWorkouts = selectedLowerBodyWorkouts;
        break;
      case 'Core':
        selectedWorkouts = selectedCoreWorkouts;
        break;
      case 'Cardio':
        selectedWorkouts = selectedCardioWorkouts;
        break;
      default:
        selectedWorkouts = [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$workoutType Workouts:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: workouts.map((workout) {
            return ChoiceChip(
              label: Text(workout),
              selected: selectedWorkouts.contains(workout),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedWorkouts.add(workout);
                  } else {
                    selectedWorkouts.remove(workout);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Workout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display workout status at the top
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: workoutStatus == 'Assigned'
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Status: $workoutStatus',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Add space below the status

              ...workoutOptions.keys.map((workoutType) {
                return _buildWorkoutSelection(
                    workoutType, workoutOptions[workoutType]!);
              }),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitWorkout,
                child: const Text('Assign Workouts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
