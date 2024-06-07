import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String username;
  final String text;
  final String link;
  final String imageUrl;
  final String videoUrl;
  final Timestamp createdAt;
  final String name;

  Post({
    required this.id,
    required this.username,
    required this.text,
    required this.link,
    required this.imageUrl,
    required this.videoUrl,
    required this.createdAt,
    required this.name,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      username: data['username'] ?? '',
      text: data['text'] ?? '',
      link: data['link'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      name: data['name'] ?? '',
    );
  }
}
