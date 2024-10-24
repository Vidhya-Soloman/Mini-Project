import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for time formatting

class DieticianChatPatient extends StatefulWidget {
  final String patientId;

  const DieticianChatPatient({super.key, required this.patientId});

  @override
  _DieticianChatPatientState createState() => _DieticianChatPatientState();
}

class _DieticianChatPatientState extends State<DieticianChatPatient> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    // Listen to messages for the specific patient ID
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.patientId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        messages = snapshot.docs.map((doc) => doc.data()).toList();
      });
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.patientId)
          .collection('messages')
          .add({
        'text': message,
        'sender': 'dietician', // Sender is the dietician
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  Future<void> _deleteChat() async {
    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Delete all messages
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.patientId)
          .collection('messages');

      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await messagesRef.get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Optionally, clear the local messages list
      setState(() {
        messages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully!')),
      );
    }
  }

  String _formatTime(Timestamp timestamp) {
    // Format the timestamp to show only the time
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Patient"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteChat, // Call delete function
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isSender = message['sender'] == 'dietician';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: isSender
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color:
                              isSender ? Colors.green[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isSender ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (message['timestamp'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            _formatTime(message['timestamp']),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_messageController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
