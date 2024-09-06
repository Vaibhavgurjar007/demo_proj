import 'package:demo_proj/model/post.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Post Detail')),
        body: Padding(padding: const EdgeInsets.all(16.0), child: _buildContent(post)));
  }

  Widget _buildContent(Post post) {
    switch (post.type) {
      case 'Text':
        return Text(post.content, style: const TextStyle(fontSize: 18));
      case 'Video':
        return VideoPost(videoUrl: post.content);
      case 'Image':
        return Image.network(post.content, fit: BoxFit.fill,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
              child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null));
        });
      default:
        return const Text('Unknown post type');
    }
  }
}

class VideoPost extends StatefulWidget {
  final String videoUrl;

  const VideoPost({super.key, required this.videoUrl});

  @override
  _VideoPostState createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    setState(() => _isInitialized = true);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_isInitialized) AspectRatio(aspectRatio: 16 / 9, child: VideoPlayer(_controller)),
      VideoProgressIndicator(_controller, allowScrubbing: true),
      IconButton(
          icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
            setState(() {});
          })
    ]);
  }
}

class ImageWithLoader extends StatefulWidget {
  final String imageUrl;

  const ImageWithLoader({super.key, required this.imageUrl});

  @override
  _ImageWithLoaderState createState() => _ImageWithLoaderState();
}

class _ImageWithLoaderState extends State<ImageWithLoader> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Image widget
        Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          width: 200,
          height: 200,
          // Update loading state
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              _isLoading = false; // Image loaded
              return child; // Return the loaded image
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          // Handle errors
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return const Text('Error loading image');
          },
        ),
        // Show loader while loading
        if (_isLoading) const CircularProgressIndicator(),
      ],
    );
  }
}
