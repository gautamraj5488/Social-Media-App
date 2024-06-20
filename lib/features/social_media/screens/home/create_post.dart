import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../../../common/widgets/appbar/appbar.dart';


class CreatePostScreen extends StatefulWidget {
  final String username;
  final String name;

  const CreatePostScreen({super.key, required this.username, required this.name});
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  File? _selectedImage;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;





  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _videoController = VideoPlayerController.file(_selectedVideo!)
          ..initialize().then((_) {
            _videoController!.setLooping(true); // Play video on loop

            // Check video duration
            if (_videoController!.value.duration.inSeconds > 60) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Selected video should be less than 1 minute."),
              ));
              _videoController!.pause();
              _selectedVideo = null;
            } else {
              setState(() {
                _videoController!.play();
              });
            }
          });
      });
    }
  }



  Future<String?> _uploadFile(File file, String path) async {
    try {
      TaskSnapshot taskSnapshot = await _storage.ref(path).putFile(file);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }


  Future<void> _submitPost() async {
    if (_textController.text.isEmpty && _selectedImage == null && _selectedVideo == null && _linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add some content to the post")));
      return;
    }

    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
    setState(() {
      isLoading = true;
    });

    String? imageUrl;
    String? videoUrl;

    String userId = _auth.currentUser!.uid;
    if (_selectedImage != null) {
      imageUrl = await _uploadFile(_selectedImage!, 'posts/$userId/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    }

    if (_selectedVideo != null) {
      videoUrl = await _uploadFile(_selectedVideo!, 'posts/$userId/videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
    }

    // Add the post data to Firestore
    await _firestore.collection('posts').add({
      'text': _textController.text,
      'link': _linkController.text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.now(),
      'username': widget.username,
      'name' : widget.name,
      'userId': userId,
      'likes': 0,
    });

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar : SMAAppBar(
        title: const Text('Create Post'),
        actions: [
          // TextButton(
          //     onPressed: (){
          //       _submitPost();
          //     },
          //     child: Text("Upload")
          // )
        ],

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                hintText: 'Add a link...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            _selectedImage == null
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.image, size: 50),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, size: 50),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            )
                : Stack(
              alignment: Alignment.topRight,
              children: [
                AspectRatio(aspectRatio: 2,child: Image.file(_selectedImage!),),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _selectedVideo == null
                ? IconButton(
              icon: const Icon(Icons.videocam, size: 50),
              onPressed: _pickVideo,
            )
                : Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 200,
                  child: _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                      : const Center(child: CircularProgressIndicator()),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedVideo = null;
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _submitPost,
                  child: Text("Upload")
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}
