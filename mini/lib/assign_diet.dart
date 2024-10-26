import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignDiet extends StatefulWidget {
  final String patientId;
  final Function onDietAssigned; // Callback for diet assignment

  const AssignDiet({
    Key? key,
    required this.patientId,
    required this.onDietAssigned,
  }) : super(key: key);

  @override
  _AssignDietState createState() => _AssignDietState();
}

class _AssignDietState extends State<AssignDiet> {
  final _formKey = GlobalKey<FormState>();
  List<String> selectedBreakfastIngredients = [];
  List<String> selectedLunchIngredients = [];
  List<String> selectedDinnerIngredients = [];
  List<String> selectedSnackIngredients = [];
  final Map<String, List<String>> mealIngredients = {
    'Breakfast': ['Oatmeal', 'Egg', 'Fruits', 'Yogurt', 'Nuts'],
    'Lunch': ['Chicken', 'Rice', 'Vegetables', 'Quinoa', 'Legumes'],
    'Dinner': ['Fish', 'Tofu', 'Vegetables', 'Pasta', 'Rice'],
    'Snacks': ['Nuts', 'Fruits', 'Greek Yogurt', 'Hummus', 'Protein Bar'],
  };

  final Map<String, TextEditingController> _controllers = {
    'Breakfast': TextEditingController(),
    'Lunch': TextEditingController(),
    'Dinner': TextEditingController(),
    'Snacks': TextEditingController(),
  };

  String dietStatus = 'Not Assigned'; // Initial status
  String patientName = ''; // To hold the patient's name

  @override
  void initState() {
    super.initState();
    _fetchDietStatus();
  }

  Future<void> _fetchDietStatus() async {
    try {
      final patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      if (patientSnapshot.exists) {
        final dietRef = patientSnapshot.data()?['dietRef'];
        patientName =
            patientSnapshot.data()?['name'] ?? ''; // Fetch the patient's name
        if (dietRef != null) {
          final dietSnapshot = await FirebaseFirestore.instance
              .collection('food')
              .doc(dietRef)
              .get();

          if (dietSnapshot.exists) {
            setState(() {
              dietStatus = dietSnapshot.data()?['status'] ?? 'Not Assigned';
            });
          }
        }
      }
    } catch (e) {
      // Handle errors
      print('Error fetching diet status: $e');
    }
  }

  Future<void> _submitDiet() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Fetch the patient's email from the users collection
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId) // Assuming patientId corresponds to user ID
          .get();

      // Prepare diet data to be saved in food collection
      final dietData = {
        'breakfast': selectedBreakfastIngredients,
        'lunch': selectedLunchIngredients,
        'dinner': selectedDinnerIngredients,
        'snacks': selectedSnackIngredients,
        'assignedAt': Timestamp.now(),
        'patientName': patientName, // Include patient name
        'status': 'Assigned', // Add status field
      };

      try {
        // Save the diet data to the food collection
        DocumentReference dietDocRef =
            await FirebaseFirestore.instance.collection('food').add(dietData);

        // Update the patient's document with the diet reference
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .update({
          'dietRef': dietDocRef.id, // Store the reference to the diet document
          'dietAssigned': true, // Mark diet as assigned
          'dietAssignedAt': Timestamp.now(), // Store the assignment time
        });

        // Notify the parent widget that the diet has been assigned
        widget.onDietAssigned();

        // Update the status to reflect the new assignment
        setState(() {
          dietStatus = 'Assigned';
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet assigned successfully!')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (error) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  void _addIngredient(String mealType) {
    final ingredient = _controllers[mealType]!.text.trim();
    if (ingredient.isNotEmpty &&
        !mealIngredients[mealType]!.contains(ingredient)) {
      setState(() {
        mealIngredients[mealType]!.add(ingredient);
        _controllers[mealType]!.clear(); // Clear the text field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Diet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display diet status at the top
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color:
                        dietStatus == 'Assigned' ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Diet Status: $dietStatus',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Add space below the status

              ...mealIngredients.keys.map((mealType) {
                return _buildMealSelection(
                    mealType, mealIngredients[mealType]!);
              }).toList(),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitDiet,
                child: const Text('Assign Diet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealSelection(String mealType, List<String> ingredients) {
    List<String> selectedIngredients;
    switch (mealType) {
      case 'Breakfast':
        selectedIngredients = selectedBreakfastIngredients;
        break;
      case 'Lunch':
        selectedIngredients = selectedLunchIngredients;
        break;
      case 'Dinner':
        selectedIngredients = selectedDinnerIngredients;
        break;
      case 'Snacks':
        selectedIngredients = selectedSnackIngredients;
        break;
      default:
        selectedIngredients = [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$mealType Ingredients:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: ingredients.map((ingredient) {
            return ChoiceChip(
              label: Text(ingredient),
              selected: selectedIngredients.contains(ingredient),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedIngredients.add(ingredient);
                  } else {
                    selectedIngredients.remove(ingredient);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controllers[mealType],
                decoration: const InputDecoration(
                  labelText: 'Add new ingredient',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addIngredient(mealType),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
