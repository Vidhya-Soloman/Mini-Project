import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientChatDiet extends StatefulWidget {
  const PatientChatDiet({super.key});

  @override
  _PatientChatDietState createState() => _PatientChatDietState();
}

class _PatientChatDietState extends State<PatientChatDiet> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _firestore.collection('chats').add({
        'senderId': user!.uid,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Dietician"),
        backgroundColor: const Color.fromARGB(255, 70, 206, 227),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderId = message['senderId'];
                    final messageText = message['message'];

                    return ListTile(
                      title: Text(
                        messageText,
                        style: TextStyle(
                          color: senderId == user!.uid
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        senderId == user!.uid ? "You" : senderId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: senderId == user!.uid
                              ? Colors.green
                              : Colors.black,
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
                    decoration: InputDecoration(
                      labelText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
