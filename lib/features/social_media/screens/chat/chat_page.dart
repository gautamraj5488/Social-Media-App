import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/features/social_media/screens/profile/profile_page.dart';
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
  ChatPage(
      {super.key,
      required this.receiverEmail,
      required this.receiverId,
      required this.receiverName,
      required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService chatService = ChatService();

  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isFriend = false;
  bool canChat = false;
  bool isAllowedToMessage = false;

  @override
  void initState() {
    super.initState();
    isCurrentUserFriend();
    isAllowedToChat();
    checkIfRequested();
    isCurrentUserFriend();
  }


  bool isRequested = true;

  Future<void> checkIfRequested() async {
    bool requested = await _fireStoreServices.isCurrentUserRequested(
        _auth.currentUser!.uid, widget.receiverId);
    setState(() {
      isRequested = requested;
    });
  }

  Future<void> isCurrentUserFriend() async {
    bool friend = await _fireStoreServices.isCurrentUserFriend(
        _auth.currentUser!.uid, widget.receiverId);
    setState(() {
      isFriend = friend;
    });
  }

  Future<void> sendFollowRequest() async {
    try {
      await _fireStoreServices.sendFollowRequest(
          _auth.currentUser!.uid, widget.receiverId);
      setState(() {
        isRequested = true;
      });
      print("Follow request sent successfully");
    } catch (e) {
      print("Error sending follow request: $e");
    }
  }

  Future<void> unsendFollowRequest() async {
    try {
      await _fireStoreServices.unsendFollowRequest(
          _auth.currentUser!.uid, widget.receiverId);
      setState(() {
        isRequested = false;
      });
      print("Follow request canceled successfully");
    } catch (e) {
      print("Error canceling follow request: $e");
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> isAllowedToChat() async {
    bool chat = await _fireStoreServices.isAllowedToChat(
        _auth.currentUser!.uid, widget.receiverId);
    if (mounted) {
      print("Setting state to: $chat");
      setState(() {
        canChat = chat;
        print("State updated. canChat: $canChat");
      });
    } else {
      print("Widget not mounted, cannot set state.");
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text.trim();
      _messageController.clear();
      await chatService.sendMessage(widget.receiverId,message);
      _fireStoreServices.updateMessageTime(uid: widget.receiverId);
    }
    _scrollToBottom();
    print(canChat);
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Route _createRoute(uid) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(uid: uid, username: widget.username, fromChat: true,),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
        appBar: SMAAppBar(
          title: GestureDetector(
            onTap: (){
              Navigator.of(context).push(_createRoute(widget.receiverId));
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName),
                Text(
                  widget.username,
                  style: const TextStyle(
                      fontSize: SMASizes.fontSizeSm,
                      color: SMAColors.textSecondary),
                )
              ],
            ),
          ),
          actions: [
            isFriend
                ? const SizedBox.shrink()
                : IconButton(
              onPressed: () {
                isRequested
                    ? showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                            "Do you want to cancel friend request"),
                        //content: Text("Do you want to send friend request to : ${widget.text}"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                unsendFollowRequest();
                                showSnackBar(context,
                                    'Follow Request Reverted');
                                Navigator.of(context).pop();
                              });
                            },
                            child: const Text("Yes"),
                          ),
                        ],
                      );
                    })
                    : showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                            "Do you want to send friend request to : ${widget.receiverName}"),
                        //content: Text("Do you want to send friend request to : ${widget.text}"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                sendFollowRequest();
                                showSnackBar(context,
                                    'Follow Request Sent');
                                Navigator.of(context).pop();
                              });
                              setState(() {

                              });
                            },
                            child: const Text("Yes"),
                          ),
                        ],
                      );
                    });
              },
              icon: Icon(
                isRequested ? Iconsax.verify : Iconsax.add_circle,
              ),
            )
          ],
          // title: Text(widget.receiverName)
        ),
        body: canChat
            ? Column(
                children: [
                  Expanded(
                    child: _buildMessageList(),
                  ),
                  isAllowedToMessage || isFriend
                      ? _buildUserInput(dark)
                      : Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  SMASizes.borderRadiusLg),
                              color: dark ? SMAColors.dark : SMAColors.light),
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.all(SMASizes.defaultSpace),
                          padding: const EdgeInsets.all(SMASizes.defaultSpace),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                  "Do you want to continue chat with : ${widget.receiverName} ?"),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                      child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          }, child: const Text("No"))),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              isAllowedToMessage = true;
                                            });
                                          },
                                          child: const Text("Yes")))
                                ],
                              )
                            ],
                          ),
                        ),
                ],
              )
            : Center(
          child: Image.asset("assets/gifs/loading.gif"),
        ));
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
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;
    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data['message'],
            isCurrentUser: isCurrentUser,
            timestamp: data['timestamp'], msgId: data['msgId'], receiverId: widget.receiverId,
          )
        ],
      ),
    );
  }

  Widget _buildUserInput(dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SMASizes.md, left: SMASizes.sm),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            child: TextField(
              decoration: const InputDecoration(
                  hintText: "Write a message",
                  hintStyle: TextStyle(color: Colors.grey)),
              controller: _messageController,
              obscureText: false,
              minLines: 1,
              maxLines: 8,
            ),
          )
        ),
        Container(
          decoration:
              const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          margin: const EdgeInsets.symmetric(horizontal: SMASizes.sm),
          child: IconButton(
            onPressed: sendMessage,
            icon: Icon(
              Iconsax.send_2,
              size: SMASizes.iconLg,
              color: dark ? SMAColors.dark : SMAColors.light,
            ),
          ),
        )
      ]),
    );
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
