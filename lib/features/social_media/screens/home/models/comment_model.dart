import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String postId;
  final String userId;
  final String text;
  final Timestamp timestamp;
  String userName;
  String userAvatarUrl;

  Comment({
    required this.postId,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.userName = 'Unknown',
    this.userAvatarUrl = '',
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      postId: map['postId'],
      userId: map['userId'],
      text: map['text'],
      timestamp: map['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'text': text,
      'timestamp': timestamp,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }
}
