import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/utils/constants/colors.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';
import 'package:social_media_app/utils/theme/custom_theme/text_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../utils/constants/sizes.dart';
import 'models/post_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('posts').get();
      List<Post> postsData =
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      setState(() {
        posts = postsData;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching posts: $e");
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: Image.asset("assets/gifs/loading.gif"))
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostWidget(post: posts[index]);
              },
            ),
    );
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
  bool _isPlaying = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<List<Map<String, dynamic>>>? mutualFollowersDataFuture;
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.post.videoUrl != '') {
      _videoController = VideoPlayerController.network(widget.post.videoUrl)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          setState(() {});
        });
    }
    mutualFollowersDataFuture =
        _fetchMutualFollowersData(_auth.currentUser!.uid);
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  Widget _buildVideoPlayer() {
    return _videoController != null && _videoController!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 50.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
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
      // Fetch current user's followers and followings
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

      // Find mutual followers
      final List<String> mutualFollowersIds =
          followers.where((follower) => followings.contains(follower)).toList();

      print('Mutual followers IDs: $mutualFollowersIds');

      // Ensure 'shared_posts' document exists
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

      // Share post with mutual followers
      for (final followerId in selectedIds) {
        print('Sharing post to follower: $followerId');
        await _firestore.collection('shared_posts').add({
          'postId': widget.post.id,
          'sharedBy': currentUserId,
          'sharedTo': followerId,
          'sharedAt': Timestamp.now(),
        });
        print('Post shared to $followerId');
      }

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

  Future<List<Map<String, dynamic>>> _fetchMutualFollowersData(
      String userId) async {
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

        // Find mutual followers' IDs
        final mutualFollowersIds =
            followers.where((user) => following.contains(user)).toList();

        // Fetch data of mutual followers
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

// Function to fetch user data from Firestore based on user IDs
  Future<List<Map<String, dynamic>>> _fetchUserData(
      List<String> userIds) async {
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
            Text(
              widget.post.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildTimestamp(),
            // if (widget.post.text != null) ...[
            //   SizedBox(height: 10),
            //   Text(widget.post.text!),
            // ],
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
                        if (widget.post.imageUrl != '')
                          BuildPhotoWidget(imageUrl: widget.post.imageUrl),
                        if (widget.post.videoUrl != '')
                          VideoPlayerWidget(videoUrl: widget.post.videoUrl),
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
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    // Handle like
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    // Handle comment
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    showModalBottomSheet(
                        isScrollControlled: false,
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
                                          style: SMATextTheme
                                              .darkTextTheme.headlineMedium,
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
                                                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                                                        'uis']; // Assuming 'id' is the key for follower ID in Firestore
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
                              ElevatedButton(onPressed: _sharePost, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12),child:Text("Share Posts"))),
                            ],
                          );
                        }).whenComplete(_onBottomSheetClosed);
                  },
                  // onPressed: _sharePost,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _videoController.setLooping(false);
        setState(() {});
      });
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('video-visibility-detector'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 0) {
          _videoController.pause();
          setState(() {
            _isPlaying = false;
          });
        }
      },
      child: _videoController.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 50.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
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
      return Image.network(
        imageUrl!,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          print('Error loading image: $error');
          print('StackTrace: $stackTrace');
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
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
