import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class TrainerChatPatient extends StatefulWidget {
  final String patientId; // ID of the patient
  final String patientName; // Name of the patient
  final String trainerName; // Name of the trainer

  const TrainerChatPatient({
    required this.patientId,
    required this.patientName,
    required this.trainerName,
    Key? key,
  }) : super(key: key);

  @override
  _TrainerChatPatientState createState() => _TrainerChatPatientState();
}

class _TrainerChatPatientState extends State<TrainerChatPatient> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isNotEmpty) {
      // Create a message object
      final messageData = {
        'trainerName': widget.trainerName,
        'patientName': widget.patientName,
        'text': message, // Change 'message' to 'text'
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'trainer', // Indicates the sender as trainer
        'patientId': widget.patientId, // Store patient ID for reference
      };

      // Sending message to Firestore in a sub-collection
      _firestore
          .collection('trainerchat')
          .doc(widget.patientId) // Document for this specific patient
          .collection('messages') // Sub-collection for messages
          .add(messageData)
          .then((_) {
        // Optionally log success
        print("Message sent: $message");
      }).catchError((error) {
        // Handle error in sending message
        print("Error sending message: $error");
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
        title: Text("Chat with ${widget.patientName}"), // Title of the chat
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

                final messagesFromFirestore =
                    snapshot.data!.docs; // Retrieve the messages

                return ListView.builder(
                  itemCount: messagesFromFirestore.length,
                  itemBuilder: (context, index) {
                    final messageData = messagesFromFirestore[index].data()
                        as Map<String, dynamic>;
                    final messageText = messageData['text'] ??
                        ''; // Use 'text' instead of 'message'
                    final isTrainer = messageData['sender'] ==
                        'trainer'; // Check if sender is trainer
                    final timestamp = messageData['timestamp']; // Get timestamp

                    return Align(
                      alignment: isTrainer
                          ? Alignment.centerRight
                          : Alignment.centerLeft, // Align based on sender
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isTrainer
                              ? Colors.blue[100]
                              : Colors
                                  .green[100], // Different colors for sender
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isTrainer
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: const TextStyle(
                                  fontSize: 16), // Make the text legible
                            ), // Display the message
                            if (timestamp !=
                                null) // Check if timestamp is not null
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
