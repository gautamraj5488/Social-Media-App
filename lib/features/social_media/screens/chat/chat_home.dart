import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        // error
        if (snapshot.hasError) {
          return const Text("Error");
        }
        // loading..
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        // return list view
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        ); // ListView
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = _fireStoreServices.getCurrentUser();
    if (currentUser != null && userData['email'] != currentUser.email) {
      return UserTile(
        text: userData['email'],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData['email'],
                receiverId: userData["uis"],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final dark = SMAHelperFunctions.isDarkMode(context);
    return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: dark ? SMAColors.darkContainer : SMAColors.lightContainer,
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
              Text(text)
            ],
          ),
        ));
  }
}
