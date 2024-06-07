import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../services/chat/chat_service.dart';
import '../../../../../services/firestore.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final Timestamp timestamp;
  final String msgId;
  final String receiverId;

  ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
    required this.msgId,
    required this.receiverId,
  });

  final ChatService chatService = ChatService();

  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _copyMessageToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
      ),
    );
  }

  void _openUrl(String url) async {
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteMessage(context);
                Navigator.of(context).pop();
                SMADeviceUtils.hideKeyboard(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void deleteMessage(BuildContext context) async {
    try {
      String chatRoomID1 = "${_auth.currentUser!.uid}_$receiverId";
      String chatRoomID2 = "${receiverId}_${_auth.currentUser!.uid}";

      bool messageDeleted = await chatService.deleteMessage(chatRoomID1, msgId);

      // If the message was not found in the first chatRoomID format, try the second format
      if (!messageDeleted) {
        messageDeleted = await chatService.deleteMessage(chatRoomID2, msgId);
      }

      if (messageDeleted) {
        SMAHelperFunctions.showSnackBar(
            context, 'Message deleted successfully');
      } else {
        SMAHelperFunctions.showSnackBar(context, 'Message not found');
      }
    } catch (e) {
      SMAHelperFunctions.showSnackBar(context, 'Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool deletedMessage = message == "";
    return Column(
      children: [
        isCurrentUser
            ? GestureDetector(
          onDoubleTap: () {
            _copyMessageToClipboard(context);
          },
          onTap: () {
            print(
                "${_auth.currentUser!.uid.toString() + "_" + receiverId}");
            print(msgId);
          },
          onLongPress: () {
            _showDeleteConfirmationDialog(context);
          },
          child: deletedMessage
              ? Container(
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.lightGreen
                    : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ), // BoxDecoration
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(
                  vertical: 2.5, horizontal: 25),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.trash, color: Colors.white70),
                  Text(
                    "This message was deleted",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ) // Text
          )
              : Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Colors.lightGreen
                  : Colors.black,
              borderRadius: BorderRadius.circular(12),
            ), // BoxDecoration
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(
                vertical: 2.5, horizontal: 25),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ), // Text
          ),
        )
            : deletedMessage
            ? Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Colors.lightGreen
                  : Colors.black,
              borderRadius: BorderRadius.circular(12),
            ), // BoxDecoration
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(
                vertical: 2.5, horizontal: 25),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.trash, color: Colors.white70),
                Text(
                  "This message was deleted",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ) // Text
        )
            : Container(
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Colors.lightGreen
                : Colors.black,
            borderRadius: BorderRadius.circular(12),
          ), // BoxDecoration
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(
              vertical: 2.5, horizontal: 25),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ), // Text
        ),
        // Text("$timestamp")
      ],
    );
  }


}
