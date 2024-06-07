import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:video_player/video_player.dart';

import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/sizes.dart';
import '../home/models/post_model.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({
    Key? key,
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

  Future<void> fetchPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('posts').where("userId",isEqualTo: _auth.currentUser!.uid).get();
      List<Post> postsData =
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      setState(() {
        posts = postsData;
        isLoading = false;
      });
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
    _userDataFuture = _fireStoreServices.getUserData();
    fetchPosts();
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
          if (userData == null) {
            return const Center(child: Text("User data not found"));
          }
          return SafeArea(
              child: Padding(
            padding: EdgeInsets.all(SMASizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                // ...List.generate(
                //   customListTiles.length,
                //       (index) {
                //     final tile = customListTiles[index];
                //     return Padding(
                //       padding: const EdgeInsets.only(bottom: 5),
                //       child: Card(
                //         elevation: 4,
                //         shadowColor: Colors.black12,
                //         child: ListTile(
                //           leading: Icon(tile.icon),
                //           title: Text(tile.title),
                //           trailing: const Icon(Icons.chevron_right),
                //         ),
                //       ),
                //     );
                //   },

               posts.length !=0
                   ? Expanded(
                  child: GridView.builder(
                    itemCount: posts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    itemBuilder: (context, index) {
                      return PostWidget(post: posts[index]);
                    },
                  ),
                )
                   : Center(child: Text("No Posts"),)
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
            SizedBox(height: 10),
            Text(widget.text),
            SizedBox(height: 10),
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
      return Center(child: Text('No video available'));
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
              padding: EdgeInsets.all(6.0),
              child: Image.network(widget.post.imageUrl!),
            ),
          )
        : Card(
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: _buildVideoPlayer(),
            ),
          );
  }
}
