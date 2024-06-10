import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:social_media_app/features/social_media/screens/chat/chat_home.dart';
import 'package:social_media_app/features/social_media/screens/chat/chat_page.dart';
import 'package:social_media_app/features/social_media/screens/profile/profile_setting_page.dart';
import 'package:social_media_app/features/social_media/screens/profile/user_profile_widget.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';
import 'package:social_media_app/utils/theme/custom_theme/text_theme.dart';
import 'package:video_player/video_player.dart';

import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/sizes.dart';
import '../home/models/post_model.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final String username;
  final bool fromChat;
  ProfilePage({
    Key? key,
    required this.uid,
    required this.username, required this.fromChat,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<DocumentSnapshot> _userDataFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> posts = [];
  bool isLoading = true;

  Future<void> loadCachedPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String cachedPosts = prefs.getString('cachedPosts${widget.uid}') ?? '[]';
    List<dynamic> cachedPostsList = json.decode(cachedPosts);
    List<Post> cachedPostsData =
        cachedPostsList.map((data) => Post.fromJson(data)).toList();
    setState(() {
      posts = cachedPostsData;
      isLoading = false;
    });
  }

  Future<void> fetchPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where("userId", isEqualTo: widget.uid)
          .get();
      List<Post> postsData =
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      setState(() {
        posts = postsData;
        isLoading = false;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedPosts${widget.uid}',
          json.encode(posts.map((post) => post.toJson()).toList()));
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fireStoreServices.getUserData(widget.uid);
    loadCachedPosts();
    fetchPosts();
    checkIfRequested();
    isCurrentUserFriend();
  }

  Route _createRoute(UserProfile userProfile) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(
        userProfile: userProfile,
      ),
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

  bool isFriend = false;
  bool isRequested = false;

  Future<void> checkIfRequested() async {
    bool requested = await _fireStoreServices.isCurrentUserRequested(
        _auth.currentUser!.uid, widget.uid);
    setState(() {
      isRequested = requested;
    });
  }

  Future<void> isCurrentUserFriend() async {
    bool friend = await _fireStoreServices.isCurrentUserFriend(
        _auth.currentUser!.uid, widget.uid);
    setState(() {
      isFriend = friend;
    });
  }

  Future<void> unfollow() async {
    await _fireStoreServices.unfollowUser(_auth.currentUser!.uid, widget.uid);
    setState(() {
      isFriend = false;
      isRequested=false;
    });
  }

  Future<void> sendFollowRequest() async {
    try {
      await _fireStoreServices.sendFollowRequest(
          _auth.currentUser!.uid, widget.uid);
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
          _auth.currentUser!.uid, widget.uid);
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
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
        appBar: SMAAppBar(
          showBackArrow: _auth.currentUser!.uid == widget.uid ? false : true,
          title: FutureBuilder<DocumentSnapshot>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox.shrink());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("User data not found"));
              } else {
                var userData = snapshot.data!.data() as Map<String, dynamic>;

                return Text(userData['username'],
                    style: dark
                        ? SMATextTheme.darkTextTheme.headlineMedium
                        : SMATextTheme.lightTextTheme.headlineMedium);
              }
            },
          ),
          actions: [
            FutureBuilder<DocumentSnapshot>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: SizedBox.shrink());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User data not found"));
                } else {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;

                  UserProfile userProfile = UserProfile(
                    firstName: userData['firstName'],
                    lastName: userData['lastName'],
                    username: userData['username'],
                    email: userData['email'],
                    phoneNumber: userData['phoneNumber'],
                    password: userData['password'],
                    uid: userData['uis'],
                    confirmPassword: userData['password'],
                    FCMtoken: userData['FCMtoken'] ?? '',
                  );

                  return userData['uis'] == _auth.currentUser!.uid
                      ? IconButton(
                          onPressed: () {
                            print("1");
                            print(userData['FCMtoken']);
                            Navigator.of(context)
                                .push(_createRoute(userProfile));
                          },
                          icon: const Icon(Iconsax.setting),
                        )
                      : isRequested? SizedBox.shrink(): IconButton(onPressed: (){
                    setState(() {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverEmail:
                                userData['email'],
                                receiverId:
                                userData['uis'],
                                receiverName: userData[
                                'firstName'] +
                                    ' ' +
                                    userData['lastName'],
                                username:
                                userData['username'],
                              )));
                    });
                  }, icon: Icon(Iconsax.message));
                }
              },
            ),
          ],
        ),
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
              if (userData == null) {
                return const Center(child: Text("User data not found"));
              }
              return SafeArea(
                  child: Padding(
                padding: const EdgeInsets.all(SMASizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: const AssetImage(
                                  'assets/user.png'), // Default placeholder image
                              child: CachedNetworkImage(
                                imageUrl: userData['profilePic'],
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 50,
                                  backgroundImage: imageProvider,
                                ),
                                placeholder: (context, url) =>
                                    const CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      AssetImage('assets/user.png'),
                                ),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      AssetImage('assets/user.png'),
                                ),
                              ),
                            ),
                            userData['profilePic'] == ''
                                ? Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Iconsax.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        padding: const EdgeInsets.all(
                                            4), // Smaller padding
                                        constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight:
                                                28), // Constraints to make it smaller
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                        FollowFollowing(
                          text: 'Posts',
                          followNumber: posts.length.toString(),
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
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['firstName'] +
                              " " +
                              userData['lastName']),
                          Text(userData['username'])
                        ],
                      ),
                    ),
                    widget.uid == _auth.currentUser!.uid
                        ? SizedBox.shrink()
                        : const SizedBox(height: SMASizes.spaceBtwSections),
                    widget.uid == _auth.currentUser!.uid
                        ? SizedBox.shrink()
                        : (isFriend || isRequested)
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      (isRequested && isFriend)
                                          ? showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      "Do you want to unfollow ?"),
                                                  //content: Text("Do you want to send friend request to : ${widget.text}"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text("No"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          unfollow();
                                                          Navigator.of(context)
                                                              .pop();
                                                        });

                                                      },
                                                      child: Text("Yes"),
                                                    ),
                                                  ],
                                                );
                                              })
                                          : unsendFollowRequest();
                                    },
                                    child: Container(
                                        height: 40,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                SMASizes.cardRadiusMd),
                                            color: Colors.grey.shade400),
                                        child: Text((isRequested && isFriend) ? "Unfollow":"Requested",
                                            style: SMATextTheme
                                                .darkTextTheme.bodyLarge)),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      widget.fromChat ? Navigator.pop(context):
                                      setState(() {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                      receiverEmail:
                                                          userData['email'],
                                                      receiverId:
                                                          userData['uis'],
                                                      receiverName: userData[
                                                              'firstName'] +
                                                          ' ' +
                                                          userData['lastName'],
                                                      username:
                                                          userData['username'],
                                                    )));
                                      });
                                    },
                                    child: Container(
                                        height: 40,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                SMASizes.cardRadiusMd),
                                            color: Colors.blue),
                                        child: Text("Message",
                                            style: SMATextTheme
                                                .darkTextTheme.bodyLarge)),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () {
                                  setState(() {
                                    sendFollowRequest();
                                    showSnackBar(
                                        context, 'Follow Request Sent');
                                  });
                                },
                                child: Container(
                                    height: 40,
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            SMASizes.cardRadiusMd),
                                        color: Colors.blue),
                                    child: Text("Follow",
                                        style: SMATextTheme
                                            .darkTextTheme.bodyLarge)),
                              ),
                    const SizedBox(height: SMASizes.spaceBtwSections),
                    Text(
                      widget.uid == _auth.currentUser!.uid
                          ? "My Posts"
                          : "Posts",
                      style: dark
                          ? SMATextTheme.darkTextTheme.headlineSmall
                          : SMATextTheme.lightTextTheme.headlineSmall,
                    ),
                    posts.length != 0
                        ? Expanded(
                            child: GridView.builder(
                              itemCount: posts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              itemBuilder: (context, index) {
                                return PostWidget(post: posts[index]);
                              },
                            ),
                          )
                        : const Expanded(child: Center(child: Text("No Posts")))
                  ],
                ),
              ));
            }
          },
        ));
  }
}

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.followNumber),
            const SizedBox(height: 10),
            Text(widget.text),
            const SizedBox(height: 10),
            // Expanded(
            //   child: GridView.builder(
            //     itemCount: posts.length,
            //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //       crossAxisCount: 3,
            //     ),
            //     itemBuilder: (context, index) {
            //       return PostWidget(post: posts[index]);
            //     },
            //   ),
            // ),
          ],
        ));
  }
}

class PostWidget extends StatefulWidget {
  final Post post;

  PostWidget({required this.post});

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.network(widget.post.videoUrl)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          setState(() {});
        });
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    } else {
      return const Center(child: Text('No video available'));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isImageAvailable = widget.post.imageUrl != null;

    return isImageAvailable
        ? Card(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.network(widget.post.imageUrl!),
            ),
          )
        : Card(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildVideoPlayer(),
            ),
          );
  }
}
