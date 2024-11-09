import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class PatientChatTrainer extends StatefulWidget {
  final String patientId; // The ID of the patient
  final String patientName; // The name of the patient
  final String trainerName; // The name of the trainer

  const PatientChatTrainer({
    required this.patientId,
    required this.patientName,
    required this.trainerName,
    super.key,
  });

  @override
  _PatientChatTrainerState createState() => _PatientChatTrainerState();
}

class _PatientChatTrainerState extends State<PatientChatTrainer> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isNotEmpty) {
      // Send message to the 'messages' sub-collection inside the 'trainerchat' collection
      _firestore
          .collection('trainerchat')
          .doc(widget.patientId) // Document for this specific patient
          .collection('messages') // Sub-collection for messages
          .add({
        'trainerName': widget.trainerName,
        'patientName': widget.patientName,
        'text': message, // Use 'text' instead of 'message'
        'timestamp': FieldValue.serverTimestamp(), // Current timestamp
        'sender': 'patient', // Indicates the sender as patient
      });
      _messageController.clear(); // Clear input field after sending
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    // Convert timestamp to DateTime
    DateTime dateTime = timestamp.toDate();
    // Format the date to a more readable format
    return DateFormat('hh:mm a').format(dateTime); // e.g. "03:30 PM"
  }

  void _deleteAllMessages() async {
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete All Messages"),
          content: const Text("Are you sure you want to delete all messages?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Proceed to delete messages
      final messagesRef = _firestore
          .collection('trainerchat')
          .doc(widget.patientId)
          .collection('messages');

      // Get all messages and delete them
      final messagesSnapshot = await messagesRef.get();
      for (var messageDoc in messagesSnapshot.docs) {
        await messageDoc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Trainer"), // Chat title
        actions: [
          IconButton(
            icon: const Icon(Icons.delete), // Delete icon
            onPressed: _deleteAllMessages, // Call delete all messages
            tooltip: "Delete All Messages",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('trainerchat')
                  .doc(widget.patientId) // Filter by patient ID
                  .collection(
                      'messages') // Stream from the messages sub-collection
                  .orderBy('timestamp') // Order messages by timestamp
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs; // Retrieve the messages

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final messageText = messageData['text'] ??
                        ''; // Use 'text' instead of 'message'
                    final sender =
                        messageData['sender']; // Get sender information
                    final timestamp = messageData['timestamp']; // Get timestamp

                    final isPatient = sender ==
                        'patient'; // Check if the sender is the patient

                    return Align(
                      alignment: isPatient
                          ? Alignment.centerRight
                          : Alignment.centerLeft, // Align based on sender
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isPatient
                              ? Colors.green[100]
                              : Colors.blue[
                                  100], // Different colors for patient and trainer
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isPatient
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: const TextStyle(
                                  fontSize: 16), // Display the message
                            ),
                            if (timestamp != null &&
                                timestamp
                                    is Timestamp) // Check if timestamp is not null and is of Timestamp type
                              Text(
                                _formatTimestamp(
                                    timestamp), // Format and display the timestamp
                                style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey), // Style for the timestamp
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText:
                          "Enter message...", // Placeholder for input field
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send), // Send icon button
                  onPressed: _sendMessage, // Call send message on press
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
