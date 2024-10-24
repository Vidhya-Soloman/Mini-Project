import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientChatDiet extends StatefulWidget {
  final String patientId;

  const PatientChatDiet({super.key, required this.patientId});

  @override
  _PatientChatDietState createState() => _PatientChatDietState();
}

class _PatientChatDietState extends State<PatientChatDiet> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
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
        'sender': 'patient', // Sender is the patient
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  Future<void> _deleteChat() async {
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

      setState(() {
        messages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully!')),
      );
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute < 10 ? '0' : ''}${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Dietician"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteChat,
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
                bool isSender = message['sender'] == 'patient';

                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Hero(
                    tag:
                        'messageHero_${widget.patientId}_${message['text']}_$index', // Unique tag for each message
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isSender ? Colors.blue[300] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['text'],
                            style: TextStyle(
                              color: isSender ? Colors.white : Colors.black,
                            ),
                          ),
                          if (message['timestamp'] != null)
                            Text(
                              formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isSender ? Colors.white70 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
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
