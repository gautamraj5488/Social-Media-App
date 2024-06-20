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

class ActivityPage extends StatefulWidget {
  ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final ChatService _chatService = ChatService();
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity",
          style: TextStyle(fontSize: SMASizes.fontSizeLg),
        ),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: dark ? SMAColors.light : SMAColors.dark,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<String>>(
      stream: _chatService.getRequestToConfirmStream(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Image.asset("assets/gifs/loading.gif"));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No requests to confirm.'));
        }

        final requestToConfirmList = snapshot.data!;
        return ListView.builder(
          itemCount: requestToConfirmList.length,
          itemBuilder: (context, index) {
            final requestId = requestToConfirmList[index];
            return FutureBuilder<Map<String, dynamic>?>(
              future: _chatService.getUserDetails(requestId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text('Loading...'),
                  );
                }
                if (userSnapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${userSnapshot.error}'),
                  );
                }
                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return ListTile(
                    title: Text('No user data available'),
                  );
                }

                final userData = userSnapshot.data!;
                final name = userData['firstName'] + " " + userData['lastName'] ?? 'No name';
                final username = userData['username'] ?? 'No username';

                return UserTile(
                  text: name,
                  username: username,
                  currentUser: _auth.currentUser!.uid,
                  otherUser: userData['uis'],
                );
              },
            );
          },
        );
      },
    );
  }
}


class UserTile extends StatefulWidget {
  final String text;
  final String username;
  final String currentUser;
  final String otherUser;

  UserTile({
    super.key,
    required this.text,
    required this.username,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final ChatService _chatService = ChatService();
  bool _isFollowingBack = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowingBack();
  }

  Future<void> _checkIfFollowingBack() async {
    _isFollowingBack = await _fireStoreServices.isFollowing(widget.currentUser, widget.otherUser);
    setState(() {});
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: dark ? SMAColors.darkContainer : SMAColors.lightContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: SMASizes.defaultSpace, vertical: SMASizes.xs),
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Iconsax.user),
          SizedBox(width: SMASizes.spaceBtwItems),
          Text(widget.text),
          Spacer(),
          IconButton(
            icon: Icon(Iconsax.add),
            onPressed: () {
              showDialog(context: context, builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Do you want to accept the follow request?"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("No"),
                    ),
                    TextButton(
                      onPressed: () {
                        _fireStoreServices.approveFollowRequest(widget.currentUser, widget.otherUser);
                        _showSnackBar(context, 'Follow Request Accepted');
                        Navigator.of(context).pop();
                      },
                      child: Text("Yes"),
                    ),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
