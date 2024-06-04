import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final Timestamp timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser, required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.green: Colors.grey.shade500,
            borderRadius: BorderRadius.circular(12),
          ), // BoxDecoration
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
          ), // Text
        ),
       // Text("$timestamp")

      ],
    );
  }
}