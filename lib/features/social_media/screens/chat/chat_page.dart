import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/services/firestore.dart';
import 'package:social_media_app/utils/constants/colors.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/formatters/formatters.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import '../../../../services/chat/chat_service.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/theme/custom_theme/text_field_theme.dart';
import 'components/chat_bubble.dart';

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverId;
  ChatPage({super.key, required this.receiverEmail, required this.receiverId});

  final TextEditingController _messageController = TextEditingController();
  final ChatService chatService = ChatService();
  final FireStoreServices _fireStoreServices = FireStoreServices();

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await chatService.sendMessage(receiverId, _messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {

    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(dark),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderID = _fireStoreServices.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: chatService.getMessages(receiverId, senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        return ListView(
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser =
        data['senderID'] == _fireStoreServices.getCurrentUser()!.uid;
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(message: data['message'], isCurrentUser: isCurrentUser, timestamp: data['timestamp'],)
        ],
      ),
    );
  }

  Widget _buildUserInput(dark) {

    return Padding(
      padding: EdgeInsets.only(bottom: SMASizes.md,left: SMASizes.sm),
      child: Row(children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Write a message",
              hintStyle: TextStyle(color: Colors.grey)
            ),
            controller: _messageController,
            obscureText: false,
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle
          ),
          margin: EdgeInsets.symmetric(horizontal: SMASizes.sm),
          child: IconButton(
            onPressed: sendMessage,
            icon: Icon(Iconsax.send_2,size: SMASizes.iconLg,color: dark? SMAColors.dark : SMAColors.light,),
          ),
        )
      ]),
    );
  }
}
