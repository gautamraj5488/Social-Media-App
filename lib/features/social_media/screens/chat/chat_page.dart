import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/services/firestore.dart';
import 'package:social_media_app/utils/constants/colors.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/formatters/formatters.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../services/chat/chat_service.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/theme/custom_theme/text_field_theme.dart';
import 'components/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  final String receiverName;
  final String username;
  ChatPage({super.key, required this.receiverEmail, required this.receiverId, required this.receiverName, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService chatService = ChatService();

  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFriend = false;

  @override
  void initState() {
    super.initState();
    checkIfRequested();
  }

  Future<void> checkIfRequested() async {
    bool friend = await _fireStoreServices.isCurrentUserRequested(_auth.currentUser!.uid, widget.receiverId);
    setState(() {
      isFriend = friend;
    });
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await chatService.sendMessage(widget.receiverId, _messageController.text);
      _messageController.clear();
    }
    _scrollToBottom();
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: SMAAppBar(
        title : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            Text(
              widget.username,
              style: TextStyle(
                  fontSize: SMASizes.fontSizeSm,
                  color: SMAColors.textSecondary
              ),
            )
          ],
        ),
        // title: Text(widget.receiverName)
      ),
      body: isFriend
          ?Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(dark),
        ],
      )
          : Center(
        child: Text("you need to be friend first"),
      )
    );
  }

  Widget _buildMessageList() {
    String senderID = _fireStoreServices.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: chatService.getMessages(widget.receiverId, senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView(
          controller: _scrollController,
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
