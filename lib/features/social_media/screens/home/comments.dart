import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';
import 'package:social_media_app/utils/theme/custom_theme/text_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../profile/profile_page.dart';
import 'models/comment_model.dart';
import 'models/post_model.dart';

class CommentSectionPage extends StatefulWidget {
  final Post post;
  const CommentSectionPage({Key? key, required this.post}) : super(key: key);

  @override
  _CommentSectionPageState createState() => _CommentSectionPageState();
}

class _CommentSectionPageState extends State<CommentSectionPage> {
  List<Comment> comments = [];
  TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: SMAAppBar(
        title: const Text('Comments'),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                PostWidget(post: widget.post, comments: comments,),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.5,
                  child: comments.isEmpty
                      ? Center(
                    child: Text("no comment"),
                  )
                      : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('posts')
                        .doc(widget.post.id)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        List<Future<Comment>> commentFutures =
                        snapshot.data!.docs.map((doc) async {
                          var comment = Comment.fromMap(
                              doc.data() as Map<String, dynamic>);
                          await _fetchUserDetails(comment);
                          return comment;
                        }).toList();

                        return FutureBuilder<List<Comment>>(
                          future: Future.wait(commentFutures),
                          builder: (context,
                              AsyncSnapshot<List<Comment>> commentsSnapshot) {
                            if (commentsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (commentsSnapshot.hasError) {
                              return Text('Error: ${commentsSnapshot.error}');
                            } else {
                              List<Comment> comments =
                                  commentsSnapshot.data ?? [];

                              return ListView.builder(
                                controller: _scrollController,
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  Comment comment = comments[index];
                                  return ListTile(
                                    leading: comment.userAvatarUrl.isNotEmpty
                                        ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          comment.userAvatarUrl),
                                    )
                                        : CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(
                                        comment.userName,
                                        style:  dark ? SMATextTheme.darkTextTheme.titleSmall : SMATextTheme.lightTextTheme.titleSmall),
                                    subtitle: Text(comment.text,
                                        style: dark
                                            ? SMATextTheme
                                            .darkTextTheme.titleSmall
                                            : SMATextTheme
                                            .lightTextTheme.titleSmall),
                                  );
                                },
                              );
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: dark ? SMAColors.dark : SMAColors.light,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                      ),
                      onSubmitted: (value) => _addComment(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.send1),
                    onPressed: () {
                      _addComment();
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _fetchComments() async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();
      List<Comment> fetchedComments = [];
      for (var doc in querySnapshot.docs) {
        Comment comment = Comment.fromMap(doc.data());
        await _fetchUserDetails(comment);
        fetchedComments.add(comment);
      }

      setState(() {
        comments = fetchedComments;
      });
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _fetchUserDetails(Comment comment) async {
    try {
      final userSnapshot =
          await _firestore.collection('users').doc(comment.userId).get();
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          comment.userName = userData['username'] ?? 'Unknown User';
          comment.userAvatarUrl = userData['profilePic'] ?? '';
        }
      } else {
        comment.userName = 'Unknown User';
        comment.userAvatarUrl = '';
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void _addComment() async {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      Comment comment = Comment(
        postId: widget.post.id,
        userId: _auth.currentUser!.uid,
        text: commentText,
        timestamp: Timestamp.now(),
        userName: '',
        userAvatarUrl: '',
      );

      try {
        DocumentSnapshot userSnapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        if (userSnapshot.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null) {
            comment.userName = userData['username'] ?? '';
            comment.userAvatarUrl = userData['profilePic'] ?? '';
          }
        }


        // setState(() {
        //   comments.add(comment);
        //   _scrollToBottom();
        //   FocusScope.of(context).unfocus();
        //   SMADeviceUtils.hideKeyboard(context);
        // });

        await _firestore
            .collection('posts')
            .doc(widget.post.id)
            .collection('comments')
            .add(comment.toMap());

        setState(() {
          comments.add(comment);
          _scrollToBottom();
          FocusScope.of(context).unfocus();
          SMADeviceUtils.hideKeyboard(context);
          _commentController.clear();
        });


      } catch (e) {
        print('Error adding comment: $e');
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}



class PostWidget extends StatefulWidget {
  final Post post;
  final List<Comment> comments;

  PostWidget({required this.post, required this.comments});

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  // VideoPlayerController? _videoController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<List<Map<String, dynamic>>>? mutualFollowersDataFuture;
  Set<String> selectedIds = {};

  int _likes= 0;
  bool _isLiked = false;


  @override
  void initState() {
    super.initState();
    mutualFollowersDataFuture =
        _fetchMutualFollowersData(_auth.currentUser!.uid);
    _checkIfLiked();
    _likes = widget.post.likes;
  }

  Widget _buildTimestamp() {
    if (widget.post.createdAt != '') {
      String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(widget.post.createdAt.toDate());
      return Text(
        formattedTimestamp,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<void> _sharePost() async {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      if (kDebugMode) {
        print('Error: No current user logged in');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    try {
      final currentUserDoc =
      await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) {
        if (kDebugMode) {
          print('Error: Current user document not found');
        }
        return;
      }

      final List<String> followers =
      List<String>.from(currentUserDoc.data()?['followers'] ?? []);
      final List<String> followings =
      List<String>.from(currentUserDoc.data()?['following'] ?? []);

      final List<String> mutualFollowersIds =
      followers.where((follower) => followings.contains(follower)).toList();

      print('Mutual followers IDs: $mutualFollowersIds');

      final sharedPostsDocRef =
      _firestore.collection('shared_posts').doc('shared_posts');
      final sharedPostsDocSnapshot = await sharedPostsDocRef.get();

      if (!sharedPostsDocSnapshot.exists) {
        print('Creating shared_posts document');
        await sharedPostsDocRef.set({
          'createdBy': currentUserId,
          'createdAt': Timestamp.now(),
        });
        print('shared_posts document created');
      }

      final batch = _firestore.batch();
      for (final followerId in mutualFollowersIds) {
        print('Sharing post to follower: $followerId');
        batch.set(
          _firestore.collection('shared_posts').doc(),
          {
            'postId': widget.post.id,
            'sharedBy': currentUserId,
            'sharedTo': followerId,
            'sharedAt': Timestamp.now(),
          },
        );
        print('Post shared to $followerId');
      }
      await batch.commit();

      print('Post shared successfully to all mutual followers.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
    } catch (e) {
      print("Error sharing post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share post: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMutualFollowersData(String userId) async {
    try {
      final followerSnapshot =
      await _firestore.collection('users').doc(userId).get();
      final followingSnapshot =
      await _firestore.collection('users').doc(userId).get();

      if (followerSnapshot.exists && followingSnapshot.exists) {
        final followers =
        List<String>.from(followerSnapshot.data()?['followers'] ?? []);
        final following =
        List<String>.from(followingSnapshot.data()?['following'] ?? []);

        final mutualFollowersIds =
        followers.where((user) => following.contains(user)).toList();

        final mutualFollowersData = await _fetchUserData(mutualFollowersIds);

        if (kDebugMode) {
          print('Mutual Followers Data: $mutualFollowersData');
        }
        return mutualFollowersData;
      } else {
        if (kDebugMode) {
          print('Follower or Following document does not exist.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching mutual followers data: $e');
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchUserData(List<String> userIds) async {
    try {
      final userDataList = <Map<String, dynamic>>[];
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userDataList.add(userDoc.data()!);
        }
      }
      return userDataList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
      return [];
    }
  }
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CommentSectionPage(
        post: widget.post,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
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




  Future<void> _checkIfLiked() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot likeSnapshot = await _firestore
          .collection('posts')
          .doc(widget.post.id)
          .collection('likes')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _isLiked = likeSnapshot.exists;
      });
    }
  }

  Future<void> _likePost(String postId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }
    DocumentReference postRef = _firestore.collection('posts').doc(postId);
    DocumentReference userLikeRef = postRef.collection('likes').doc(currentUser.uid);

    if (!_isLiked) {
      try {
        await userLikeRef.set({
          'likedAt': Timestamp.now(),
        });
        await postRef.update({
          'likes': FieldValue.increment(1),
        });

        setState(() {
          _likes++;
          _isLiked = true;
        });
      } catch (e) {
        print('Error liking post: $e');
      }
    } else {
      try {
        await userLikeRef.delete();
        await postRef.update({
          'likes': FieldValue.increment(-1),
        });

        setState(() {
          _likes--;
          _isLiked = false;
        });
      } catch (e) {
        print('Error unliking post: $e');
      }
    }
  }




  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    bool dark = SMAHelperFunctions.isDarkMode(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if(widget.post.uid != _auth.currentUser!.uid){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfilePage(uid: widget.post.uid, username: widget.post.username, fromChat: false)));
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildTimestamp(),
                ],
              ),
            ),
            DescriptionTextWidget(
              text: widget.post.text,
            ),
            const SizedBox(height: 10),
            if (widget.post.link != '') ...[
              const SizedBox(height: 10),
              GestureDetector(
                onLongPress: () {
                  SMAHelperFunctions.copyMessageToClipboard(
                      context, widget.post.link);
                },
                onTap: () {
                  SMADeviceUtils.launchUrl(context, widget.post.link);
                },
                child: Text(
                  widget.post.link,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              height: widget.post.imageUrl == "" && widget.post.videoUrl == ""
                  ? 0
                  : 200,
              width: double.infinity,
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        if (widget.post.imageUrl.isNotEmpty)
                          BuildPhotoWidget(imageUrl: widget.post.imageUrl),
                        if (widget.post.videoUrl.isNotEmpty)
                          VideoPlayerWidget(videoUrl: widget.post.videoUrl,imageUrl: widget.post.imageUrl, videoKey: widget.post.videoUrl,),
                      ],


                    ),
                  ),
                  const SizedBox(height: 10),
                  DotsIndicator(
                    dotsCount:
                    widget.post.imageUrl != "" && widget.post.videoUrl != ""
                        ? 2
                        : 1,
                    position: _currentPage.toInt(),
                    decorator: DotsDecorator(
                      size: const Size.square(8.0),
                      activeSize: const Size(16.0, 8.0),
                      activeShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: _isLiked
                          ? Icon(Iconsax.heart5,color: Colors.red,)
                          : Icon(Iconsax.heart),
                      onPressed: () {
                        _likePost(widget.post.id); // Call _likePost function with the post id
                      },
                    ),
                    Text(
                      '$_likes', // Display the number of likes
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                // Row(
                //   children: [
                //     IconButton(
                //         icon: const Icon(Iconsax.message),
                //         onPressed: () {
                //           Navigator.of(context).push(_createRoute());
                //         }
                //     ),
                //     Text(
                //       "${widget.comments.length}",
                //       style: TextStyle(fontSize: 18),
                //     ),
                //   ],
                // ),
                IconButton(
                  icon: const Icon(Iconsax.share),
                  onPressed: () {
                    showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (BuildContext context) {
                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          "Share this with...",
                                          style:  dark ? SMATextTheme
                                              .darkTextTheme.headlineMedium : SMATextTheme
                                              .lightTextTheme.headlineMedium,
                                        ),
                                      ),
                                      StatefulBuilder(builder:
                                          (BuildContext context,
                                          StateSetter setState) {
                                        return FutureBuilder<
                                            List<Map<String, dynamic>>>(
                                          future: mutualFollowersDataFuture,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                  CircularProgressIndicator());
                                            } else if (snapshot.hasError) {
                                              return Center(
                                                  child: Text(
                                                      'Error: ${snapshot.error}'));
                                            } else if (snapshot.hasData) {
                                              final List<Map<String, dynamic>>
                                              mutualFollowersData =
                                              snapshot.data!;
                                              if (mutualFollowersData.isEmpty) {
                                                return const Center(
                                                    child: Text(
                                                        'No mutual followers found.'));
                                              } else {
                                                return GridView.builder(
                                                  physics:
                                                  NeverScrollableScrollPhysics(),
                                                  gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing: SMASizes
                                                        .gridViewSpacing,
                                                    mainAxisSpacing: SMASizes
                                                        .gridViewSpacing,
                                                  ),
                                                  shrinkWrap: true,
                                                  itemCount: mutualFollowersData
                                                      .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final followerData =
                                                    mutualFollowersData[
                                                    index];
                                                    final String id = followerData[
                                                    'uis']; // Assuming 'uid' is the key for follower ID in Firestore
                                                    final bool isSelected =
                                                    selectedIds
                                                        .contains(id);

                                                    return GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            if (isSelected) {
                                                              selectedIds.remove(
                                                                  id); // Unselect if already selected
                                                            } else {
                                                              selectedIds.add(
                                                                  id); // Select if not selected
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          margin:
                                                          const EdgeInsets
                                                              .all(12),
                                                          padding:
                                                          const EdgeInsets
                                                              .all(4),
                                                          decoration:
                                                          BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                  12),
                                                              color: dark
                                                                  ? isSelected
                                                                  ? Colors.blue.withOpacity(
                                                                  0.4)
                                                                  : SMAColors
                                                                  .darkContainer
                                                                  : SMAColors
                                                                  .lightContainer),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                            children: [
                                                              CircleAvatar(
                                                                radius: MediaQuery.of(
                                                                    context)
                                                                    .size
                                                                    .width *
                                                                    0.1,
                                                                backgroundImage: followerData[
                                                                'avatarUrl'] !=
                                                                    null
                                                                    ? NetworkImage(
                                                                    followerData[
                                                                    'avatarUrl'])
                                                                    : null,
                                                                child: followerData[
                                                                'avatarUrl'] ==
                                                                    null
                                                                    ? const Icon(
                                                                    Icons
                                                                        .person,
                                                                    size:
                                                                    30)
                                                                    : null,
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                followerData[
                                                                'firstName'] +
                                                                    " " +
                                                                    followerData[
                                                                    'lastName'] ??
                                                                    'No Name',
                                                                style: dark
                                                                    ? isSelected
                                                                    ? SMATextTheme
                                                                    .darkTextTheme
                                                                    .headlineSmall!
                                                                    .copyWith(
                                                                    color: Colors
                                                                        .blue)
                                                                    : SMATextTheme
                                                                    .darkTextTheme
                                                                    .headlineSmall
                                                                    : SMATextTheme
                                                                    .lightTextTheme
                                                                    .bodySmall,
                                                                textAlign:
                                                                TextAlign
                                                                    .center,
                                                                overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                              ),
                                                              Text(
                                                                followerData[
                                                                'username'] ??
                                                                    'No username',
                                                                style: dark
                                                                    ? isSelected
                                                                    ? SMATextTheme
                                                                    .darkTextTheme
                                                                    .bodySmall!
                                                                    .copyWith(
                                                                    color: Colors
                                                                        .blue)
                                                                    : SMATextTheme
                                                                    .darkTextTheme
                                                                    .bodySmall
                                                                    : SMATextTheme
                                                                    .lightTextTheme
                                                                    .bodySmall,
                                                                textAlign:
                                                                TextAlign
                                                                    .center,
                                                                overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                              ),
                                                            ],
                                                          ),
                                                        ));
                                                  },
                                                );
                                              }
                                            } else {
                                              return const Center(
                                                  child: Text(
                                                      'No data available.'));
                                            }
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: mutualFollowersDataFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox.shrink(); // Optionally show a loading indicator
                                  } else if (snapshot.hasError) {
                                    return SizedBox.shrink();
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return SizedBox.shrink();
                                  }
                                  final List<Map<String, dynamic>> mutualFollowersData = snapshot.data!;
                                  if (mutualFollowersData.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  else {
                                    return ElevatedButton(
                                      onPressed: () {
                                        _sharePost();
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                        child: Text("Share Posts"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        }).whenComplete(_onBottomSheetClosed);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomSheetClosed() {
    selectedIds.clear();
  }
}


class DescriptionTextWidget extends StatefulWidget {
  final String text;

  DescriptionTextWidget({required this.text});

  @override
  _DescriptionTextWidgetState createState() => _DescriptionTextWidgetState();
}

class _DescriptionTextWidgetState extends State<DescriptionTextWidget> {
  String? firstHalf;
  String? secondHalf;

  bool flag = true;

  @override
  void initState() {
    super.initState();

    if (widget.text.length > 50) {
      firstHalf = widget.text.substring(0, 100);
      secondHalf = widget.text.substring(100, widget.text.length);
    } else {
      firstHalf = widget.text;
      secondHalf = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          flag = !flag;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: secondHalf!.isEmpty
            ? Text(firstHalf!)
            : Column(
          children: <Widget>[
            Text(
                flag ? (firstHalf! + "...") : (firstHalf! + secondHalf!)),
            InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    flag ? "more" : "less",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  flag = !flag;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String videoKey;
  final String imageUrl;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.videoKey,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() {
    Uri uri = Uri.parse(widget.videoUrl);
    _videoController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        _videoController.setLooping(true);
        setState(() {
          _videoInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoInitialized) {
      return VisibilityDetector(
        key: Key(widget.videoKey),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction == 0) {
            _videoController.pause();
          } else {
            _videoController.play();
          }
        },
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController),
              _buildBufferingIndicator(),
            ],
          ),
        ),
      );
    } else {
      // Return a placeholder widget or an empty container if video is not initialized
      return Image.asset("assets/gifs/loading.gif");
    }
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: _videoController.value.isBuffering
          ? CircularProgressIndicator()
          : SizedBox.shrink(),
    );
  }
}




class BuildPhotoWidget extends StatelessWidget {
  final String? imageUrl;

  const BuildPhotoWidget({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildPhoto();
  }

  Widget _buildPhoto() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) {
          print('Error loading image: $error');
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text(
                'Failed to load image.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          );
        },
        fit: BoxFit.cover,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}