import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/common/widgets/appbar/appbar.dart';
import 'package:social_media_app/utils/helpers/helper_fuctions.dart';
import 'package:social_media_app/utils/theme/custom_theme/text_theme.dart';
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
      body: Column(
        children: [
          Expanded(
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
                                      style: TextStyle(color: Colors.white60),
                                    ),
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
          Padding(
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
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _addComment();
                  },
                ),
              ],
            ),
          ),
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

        await _firestore
            .collection('posts')
            .doc(widget.post.id)
            .collection('comments')
            .add(comment.toMap());

        setState(() {
          comments.add(comment);
          _commentController.clear();
          _scrollToBottom();
          FocusScope.of(context).unfocus();
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
