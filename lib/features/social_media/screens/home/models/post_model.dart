import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String uid;
  final String id;
  final String username;
  final String text;
  final String link;
  final String imageUrl;
  final String videoUrl;
  final Timestamp createdAt;
  final String name;
  final String profilePic;
  final int likes;

  Post({
    required this.uid,
    required this.id,
    required this.username,
    required this.text,
    required this.link,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.name,
    required this.profilePic,
    required this.likes,
  });


  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    return Post(
      uid : data['userId'],
      id: doc.id,
      username: data['username'] ?? '',
      text: data['text'] ?? '',
      link: data['link'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      name: data['name'] ?? '', profilePic: data['profilePic'] ?? '', likes: data['likes'],
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      uid: json['uid'],
      id: json['id'],
      username: json['username'] ?? '',
      text: json['text'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? '', likes: json['likes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'id': id,
      'username': username,
      'text': text,
      'link': link,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'name': name,
      'profilePic': profilePic,
      'likes':likes,
    };
  }
}
