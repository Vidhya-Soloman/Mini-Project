import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainerChatPatient extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String trainerName;

  const TrainerChatPatient({
    required this.patientId,
    required this.patientName,
    required this.trainerName,
    super.key,
  });

  @override
  _TrainerChatPatientState createState() => _TrainerChatPatientState();
}

class _TrainerChatPatientState extends State<TrainerChatPatient> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? workoutStatus;

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isNotEmpty) {
      final messageData = {
        'trainerName': widget.trainerName,
        'patientName': widget.patientName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'trainer',
        'patientId': widget.patientId,
      };

      _firestore
          .collection('trainerchat')
          .doc(widget.patientId)
          .collection('messages')
          .add(messageData);

      _messageController.clear();
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  void _deleteAllMessages() async {
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
      final messagesRef = _firestore
          .collection('trainerchat')
          .doc(widget.patientId)
          .collection('messages');
      final messagesSnapshot = await messagesRef.get();
      for (var messageDoc in messagesSnapshot.docs) {
        await messageDoc.reference.delete();
      }
    }
  }

  void _fetchWorkoutStatus() async {
    final workoutSnapshot = await _firestore
        .collection('workouts')
        .where('patientId', isEqualTo: widget.patientId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (workoutSnapshot.docs.isNotEmpty) {
      setState(() {
        workoutStatus = workoutSnapshot.docs.first.data()['status'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWorkoutStatus(); // Fetch the workout status when the chat is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.patientName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAllMessages,
            tooltip: "Delete All Messages",
          ),
        ],
      ),
      body: Column(
        children: [
          if (workoutStatus != null) // Display the workout status
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Current Workout Status: $workoutStatus",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('trainerchat')
                  .doc(widget.patientId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messagesFromFirestore = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messagesFromFirestore.length,
                  itemBuilder: (context, index) {
                    final messageData = messagesFromFirestore[index].data()
                        as Map<String, dynamic>;
                    final messageText = messageData['text'] ?? '';
                    final isTrainer = messageData['sender'] == 'trainer';
                    final timestamp = messageData['timestamp'];

                    return Align(
                      alignment: isTrainer
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color:
                              isTrainer ? Colors.blue[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isTrainer
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (timestamp != null)
                              Text(
                                _formatTimestamp(timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
                      hintText: "Enter message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
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
