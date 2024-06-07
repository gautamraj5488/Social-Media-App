import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/post_model.dart';

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
      _videoController = VideoPlayerController.networkUrl(widget.post.videoUrl as Uri)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
              widget.post.username,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.post.createdAt.toString(),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (widget.post.text != null) ...[
              SizedBox(height: 10),
              Text(widget.post.text!),
            ],
            if (widget.post.link != null) ...[
              SizedBox(height: 10),
              Text(widget.post.link!, style: TextStyle(color: Colors.blue)),
            ],
            PageView(

              children: [
                if (widget.post.imageUrl != null) ...[
                  SizedBox(height: 10),
                  Image.network(widget.post.imageUrl!),
                ],
                if (widget.post.videoUrl != null) ...[
                  SizedBox(height: 10),
                  _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                      : Center(child: Image.asset("assets/gifs/loading.gif")),
                ],
              ],
            ),
            if (widget.post.imageUrl != null) ...[
              SizedBox(height: 10),
              Image.network(widget.post.imageUrl!),
            ],
            if (widget.post.videoUrl != null) ...[
              SizedBox(height: 10),
              _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : Center(child: Image.asset("assets/gifs/loading.gif")),
            ],
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
