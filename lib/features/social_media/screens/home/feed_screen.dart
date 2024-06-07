import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/utils/device/device_utility.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
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
      print("Error fetching posts: $e");
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

  @override
  void initState() {
    super.initState();
    if (widget.post.videoUrl != null) {
      _videoController = VideoPlayerController.network(widget.post.videoUrl!)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          setState(() {});
        });
    }
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
        : SizedBox.shrink();
  }

  Widget _buildPhoto() {
    if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
      return Image.network(widget.post.imageUrl!);
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildTimestamp() {
    if (widget.post.createdAt != null) {
      String formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(widget.post.createdAt.toDate());
      return Text(
        formattedTimestamp,
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future<void> _sharePost() async {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      print('Error: No current user logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    try {
      // Ensure 'shared_posts' document exists
      final sharedPostsDocRef = _firestore.collection('shared_posts').doc('shared_posts');
      final sharedPostsDocSnapshot = await sharedPostsDocRef.get();

      if (!sharedPostsDocSnapshot.exists) {
        print('Creating shared_posts document');
        await sharedPostsDocRef.set({
          'createdBy': currentUserId,
          'createdAt': Timestamp.now(),
        });
        print('shared_posts document created');
      }

      print('Fetching mutual followers for user: $currentUserId');
      final List<String> mutualFollowers = await _fetchMutualFollowers(currentUserId);

      print('Mutual followers: $mutualFollowers');

      for (String followerId in mutualFollowers) {
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
        SnackBar(content: Text('Post shared successfully!')),
      );
    } catch (e) {
      print("Error sharing post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share post: $e')),
      );
    }
  }

  Future<List<String>> _fetchMutualFollowers(String userId) async {
    try {
      final followerSnapshot = await _firestore.collection('users').doc(userId).get();
      final followingSnapshot = await _firestore.collection('users').doc(userId).get();

      if (followerSnapshot.exists && followingSnapshot.exists) {
        final followers = List<String>.from(followerSnapshot.data()?['followers'] ?? []);
        final following = List<String>.from(followingSnapshot.data()?['following'] ?? []);
        print('Followers: $followers');
        print('Following: $following');
        return followers.where((user) => following.contains(user)).toList();
      } else {
        print('Follower or Following document does not exist.');
      }
    } catch (e) {
      print('Error fetching mutual followers: $e');
    }
    return [];
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildTimestamp(),
            // if (widget.post.text != null) ...[
            //   SizedBox(height: 10),
            //   Text(widget.post.text!),
            // ],
            DescriptionTextWidget(text: widget.post.text,),
            SizedBox(height: 10),
            if (widget.post.link != null) ...[
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  SMADeviceUtils.launchUrl(widget.post.link);
                },
                child: Text(
                  widget.post.link!,
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
            SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.post.imageUrl != null) ...[
                      SizedBox(height: 10),
                      _buildPhoto(),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: VideoPlayerWidget(
                        videoUrl: widget.post.videoUrl!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up),
                  onPressed: () {
                    // Handle like
                  },
                ),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: () {
                    // Handle comment
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: _sharePost,
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
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: secondHalf!.isEmpty
            ? Text(firstHalf!)
            : Column(
          children: <Widget>[
            Text(flag ? (firstHalf! + "...") : (firstHalf! + secondHalf!)),
            InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    flag ? "more" : "less",
                    style: TextStyle(color: Colors.blue),
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
      key: Key('video-visibility-detector'),
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
          : SizedBox.shrink(),
    );
  }

@override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }
}
