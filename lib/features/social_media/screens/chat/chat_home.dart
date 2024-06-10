import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import 'chat_page.dart';

class ChatHomePage extends StatefulWidget {
  ChatHomePage({super.key});
  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final ChatService _chatService = ChatService();
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SMAAppBar(
        title: Text(
          "Messages",
          style: TextStyle(fontSize: SMASizes.fontSizeLg),
        ),
        showBackArrow: false,
        actions: [IconButton(onPressed: () {}, icon: Icon(Iconsax.more))],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Image.asset("assets/gifs/loading.gif"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Image.asset("assets/gifs/loading.gif"),
          );
        }

        // Extract the user data from the snapshot
        List<Map<String, dynamic>> usersData = List.from(snapshot.data!);

        // Sort the usersData list based on the timestamp in decreasing order
        usersData.sort((a, b) {
          final aMessageUpdatedAt = a['messageUpdatedAt'];
          final bMessageUpdatedAt = b['messageUpdatedAt'];

          // Handle cases where either timestamp is null
          if (aMessageUpdatedAt == null && bMessageUpdatedAt == null) {
            return 0;
          } else if (aMessageUpdatedAt == null) {
            return 1; // Place nulls at the end
          } else if (bMessageUpdatedAt == null) {
            return -1; // Place nulls at the end
          } else {
            return bMessageUpdatedAt.compareTo(aMessageUpdatedAt);
          }
        });


        // return list view
        return ListView(
          children: usersData
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        ); // ListView
      },
    );
  }



  // Widget _buildUserListItem(
  //     Map<String, dynamic> userData, BuildContext context) {
  //   final currentUser = _fireStoreServices.getCurrentUser();
  //
  //   if (currentUser != null && userData['email'] != currentUser.email) {
  //     return UserTile(
  //       text: userData['firstName'] + ' ' + userData['lastName'],
  //       username: userData['username'],
  //       currentUser: _auth.currentUser!.uid,
  //       otherUser: userData['uis'],
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => ChatPage(
  //               receiverEmail: userData['email'],
  //               receiverId: userData["uis"],
  //               receiverName:
  //                   userData['firstName'] + ' ' + userData['lastName'],
  //               username: userData['username'],
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   } else {
  //     return Container();
  //   }
  // }

  Widget _buildUserListItem(
      Map<String, dynamic> userData,
      BuildContext context,
      ) {
    final currentUser = _fireStoreServices.getCurrentUser();

    if (currentUser != null && userData['email'] != currentUser.email) {
      return FutureBuilder<DocumentSnapshot>(
        future: _fireStoreServices.getUserData(userData['uis']), // Assuming this method retrieves the user data including the timestamp
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Image.asset("assets/gifs/loading.gif"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Image.asset("assets/gifs/loading.gif"),
            );
          }

          // Extract timestamp data from the user data
          Timestamp timestamp = snapshot.data!.get('messageUpdatedAt');

          return UserTile(
            text: userData['firstName'] + ' ' + userData['lastName'],
            username: userData['username'],
            currentUser: _auth.currentUser!.uid,
            otherUser: userData['uis'],
            timestamp: timestamp, // Pass the timestamp to the UserTile
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverEmail: userData['email'],
                    receiverId: userData['uis'],
                    receiverName: userData['firstName'] + ' ' + userData['lastName'],
                    username: userData['username'],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return Container();
    }
  }

}

class UserTile extends StatefulWidget {
  final String text;
  final void Function()? onTap;
  final String username;
  final String currentUser;
  final String otherUser;
  final Timestamp timestamp;
  UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.username,
    required this.currentUser,
    required this.otherUser,
    required this.timestamp,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  final FireStoreServices _fireStoreServices = FireStoreServices();

  @override
  void initState() {
    super.initState();
    checkIfRequested();
    isCurrentUserFriend();
  }

  bool isFriend = false;
  bool isRequested = false;

  Future<void> checkIfRequested() async {
    bool requested = await _fireStoreServices.isCurrentUserRequested(
        widget.currentUser, widget.otherUser);
    setState(() {
      isRequested = requested;
    });
  }

  Future<void> isCurrentUserFriend() async {
    bool friend = await _fireStoreServices.isCurrentUserFriend(
        widget.currentUser, widget.otherUser);
    setState(() {
      isFriend = friend;
    });
  }

  Future<void> sendFollowRequest() async {
    try {
      await _fireStoreServices.sendFollowRequest(
          widget.currentUser, widget.otherUser);
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
          widget.currentUser, widget.otherUser);
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

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    return isRequested || isFriend
        ? GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color:
                    dark ? SMAColors.darkContainer : SMAColors.lightContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.symmetric(
                  horizontal: SMASizes.defaultSpace, vertical: SMASizes.xs),
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Iconsax.user),
                  SizedBox(
                    width: SMASizes.spaceBtwItems,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Text(
                      widget.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Spacer(),
                  isFriend
                      ? SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            isRequested
                                ? showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            "Do you want to cancel friend request"),
                                        //content: Text("Do you want to send friend request to : ${widget.text}"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("No"),
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
                                            child: Text("Yes"),
                                          ),
                                        ],
                                      );
                                    })
                                : showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            "Do you want to send friend request to : ${widget.text}"),
                                        //content: Text("Do you want to send friend request to : ${widget.text}"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                sendFollowRequest();
                                                showSnackBar(context,
                                                    'Follow Request Sent');
                                                Navigator.of(context).pop();
                                              });
                                            },
                                            child: Text("Yes"),
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
              ),
            ))
        : SizedBox.shrink();
  }
}
