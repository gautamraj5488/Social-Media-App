import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/features/authentication/screens/login/login.dart';

import '../../../../services/firestore.dart';
import 'activity.dart';
import 'create_post.dart';
import 'feed_screen.dart';
import 'models/post_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final user = FirebaseAuth.instance.currentUser!;
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: YourAppBar(),

      body:FutureBuilder<QuerySnapshot>(
        future: _firestore.collection('posts').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Image.asset("assets/gifs/loading.gif"));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching data'),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No posts available'),
            );
          } else {
            List<Post> posts = snapshot.data!.docs.map((doc) => Post.fromFirestore(doc)).toList();
            // Display the list of posts using a FeedScreen or any other widget
            return FeedScreen();
          }
        },
      )


    );
  }
}



class YourAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        User? currentUser = snapshot.data;

        if (currentUser == null) {
          return AppBar(
            title: Text('User not found'),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(currentUser.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return AppBar(
                title: Text('Loading...'),
              );
            } else if (userSnapshot.hasError) {
              return AppBar(
                title: Text('Error'),
              );
            } else if (!userSnapshot.hasData || userSnapshot.data == null) {
              return AppBar(
                title: Text('User not found'),
              );
            } else {
              Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
              String username = userData['username'] ?? '';
              String firstName = userData['firstName'] ?? '';
              String name = '$firstName ${userData['lastName'] ?? ''}';

              return AppBar(
                title: Text('Welcome, $firstName'),
                actions: [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                //color: Colors.white,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(12),topLeft: Radius.circular(12))
                            ),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Text('Are you sure to Logout ?'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        FirebaseAuth.instance.signOut();
                                        Navigator.pop(context);
                                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context)=> LoginScreen()), (route)=>false);

                                      },
                                      child: Text('Yes'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Close'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      );
                     // FirebaseAuth.instance.signOut();
                     // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context)=> LoginScreen()), (route)=>false);
                    },
                    icon: Icon(Iconsax.logout),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityPage()));
                    },
                    icon: Icon(Iconsax.activity),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostScreen(
                            username: username,
                            name: name,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Iconsax.undo),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
}



