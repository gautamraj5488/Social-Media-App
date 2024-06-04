import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';

import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/sizes.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FireStoreServices _fireStoreServices = FireStoreServices();

  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   elevation: 0,
        //   backgroundColor: Colors.transparent,
        //   foregroundColor: Colors.black,
        //   title: const Text("PROFILE"),
        //   centerTitle: false,
        //   actions: [
        //     IconButton(
        //       onPressed: () {},
        //       icon: const Icon(Icons.settings_rounded),
        //     )
        //   ],
        // ),

        body: FutureBuilder<DocumentSnapshot>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found"));
        } else {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          return SafeArea(child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      "https://images.unsplash.com/photo-1554151228-14d9def656e4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=386&q=80",
                    ),
                  ),
                  FollowFollowing(
                    text: 'Posts',
                    followNumber: '5',
                  ),
                  FollowFollowing(
                    text: 'Followers',
                    followNumber: userData['followers'].length.toString(),
                  ),
                  FollowFollowing(
                    text: 'Following',
                    followNumber: userData['following'].length.toString(),
                  )
                ],
              ),
              //const SizedBox(height: SMASizes.defaultSpace),
              Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['firstName'] + " " + userData['lastName']),
                    Text(userData['username'])
                  ],
                ),
              ),
              const SizedBox(height: SMASizes.defaultSpace),
              ...List.generate(
                customListTiles.length,
                (index) {
                  final tile = customListTiles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      child: ListTile(
                        leading: Icon(tile.icon),
                        title: Text(tile.title),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              )
            ],
          ));
        }
      },
    ));
  }
}

class CustomListTile {
  final IconData icon;
  final String title;
  CustomListTile({
    required this.icon,
    required this.title,
  });
}

List<CustomListTile> customListTiles = [
  CustomListTile(
    icon: Icons.insights,
    title: "Activity",
  ),
  CustomListTile(
    icon: Icons.location_on_outlined,
    title: "Location",
  ),
  CustomListTile(
    title: "Notifications",
    icon: CupertinoIcons.bell,
  ),
  CustomListTile(
    title: "Logout",
    icon: CupertinoIcons.arrow_right_arrow_left,
  ),
];

class FollowFollowing extends StatefulWidget {
  final String text;
  final String followNumber;
  const FollowFollowing(
      {super.key, required this.text, required this.followNumber});

  @override
  State<FollowFollowing> createState() => _FollowFollowingState();
}

class _FollowFollowingState extends State<FollowFollowing> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SMASizes.sm),
      child: Column(
        children: [
          Text(widget.followNumber),
          Text(widget.text),
        ],
      ),
    );
  }
}
