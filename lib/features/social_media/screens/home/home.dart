import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:social_media_app/features/authentication/screens/login/login.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';

import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData(_auth.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: YourAppBar(),
        body: FutureBuilder<QuerySnapshot>(
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
              List<Post> posts = snapshot.data!.docs
                  .map((doc) => Post.fromFirestore(doc))
                  .toList();
              // Display the list of posts using a FeedScreen or any other widget
              return FeedScreen();
            }
          },
        ));
  }
}

class YourAppBar extends StatefulWidget implements PreferredSizeWidget {
  const YourAppBar({super.key});
  @override
  State<YourAppBar> createState() => _YourAppBarState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class _YourAppBarState extends State<YourAppBar> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;


  int requestToConfirmLength = 0;

  @override
  void initState() {
    super.initState();
    _getRequestToConfirmLength();
  }

  Future<void> _getRequestToConfirmLength() async {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      if (kDebugMode) {
        print('Error: No current user logged in');
      }
      return;
    }

    try {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic>
        if (userData != null) {
          final List<dynamic>? requestToConfirm = userData['requestToConfirm'] as List<dynamic>?; // Access the 'requestToConfirm' key
          setState(() {
            requestToConfirmLength = requestToConfirm?.length ?? 0;
          });
        } else {
          print('User data is null');
        }
      } else {
        print('User document not found');
      }

    } catch (e) {
      print('Error fetching requestToConfirm list: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
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
              Map<String, dynamic> userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              String username = userData['username'] ?? '';
              String firstName = userData['firstName'] ?? '';
              String name = '$firstName ${userData['lastName'] ?? ''}';

              return AppBar(
                title: Text('Welcome, $firstName'),
                actions: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ActivityPage()),
                          );
                        },
                        icon: Icon(Iconsax.activity),
                      ),
                      requestToConfirmLength!=0?Positioned(
                        top: 1,
                        right: 3,
                        child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(width: 1,color: dark? SMAColors.white : SMAColors.black)
                        ),
                        child: Text(requestToConfirmLength.toString(),style: TextStyle(fontSize: 10,fontWeight: FontWeight.w600),),
                      ),) :SizedBox.shrink()
                    ],
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
                    icon: Icon(Iconsax.add),
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
