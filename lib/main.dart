import 'dart:convert';

import 'package:demo_proj/model/post.dart';
import 'package:demo_proj/screens/post_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:uni_links3/uni_links.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DeepLink Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    const PostPage(type: 'Text'),
    const PostPage(type: 'Video'),
    const PostPage(type: 'Image')
  ];

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      debugPrint('Initial link: $initialLink');
      if (initialLink != null) {
        handleIncomingLink(initialLink);
      }
    } on PlatformException {
      debugPrint('Failed to get initial link');
    }

    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        handleIncomingLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('Error: $err');
    });
  }

  void handleIncomingLink(String link) {
    final uri = Uri.parse(link);
    debugPrint('Received link: $uri');
    final postType = uri.queryParameters['type'];
    final postContent = uri.queryParameters['content'];
    debugPrint('Post type from link: $postType');

    if (postType != null && postContent != null) {
      final realUrl = 'https://cleanuri.com/$postContent';
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailPage(post: Post(type: postType, content: realUrl))));
    } else {
      debugPrint('Post type or content not found in link');
    }
  }

  void onTabTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('My Flutter App')),
        body: _children[_currentIndex],
        bottomNavigationBar:
            BottomNavigationBar(onTap: onTabTapped, currentIndex: _currentIndex, items: const [
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'Text'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Image')
        ]));
  }
}

class PostPage extends StatefulWidget {
  final String type;

  const PostPage({super.key, required this.type});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  bool loader = false;
  final List<Map<String, String>> _textPosts = [
    {'content': 'This is a sample text post.'},
    {'content': 'Another text post example.'},
    {'content': 'Check out this interesting text post.'},
  ];

  final List<Map<String, String>> _videoPosts = [
    {'content': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4'},
    {'content': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4'},
    {
      'content':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4'
    },
    {'content': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4'},
    {'content': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4'},
    {
      'content':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4'
    },
  ];

  final List<Map<String, String>> _imagePosts = [
    {'content': 'https://picsum.photos/seed/picsum/200/300'},
    {'content': 'https://farm2.staticflickr.com/1533/26541536141_41abe98db3_z_d.jpg'},
    {'content': 'https://farm4.staticflickr.com/3075/3168662394_7d7103de7d_z_d.jpg'},
    {'content': 'https://farm3.staticflickr.com/2220/1572613671_7311098b76_z_d.jpg'},
    {'content': 'https://farm3.staticflickr.com/2378/2178054924_423324aac8.jpg'},
  ];

  Future<String?> shortenUrl(String longUrl) async {
    setState(() => loader = true);
    try {
      const String apiUrl = 'https://cleanuri.com/api/v1/shorten';
      final response = await http.post(Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({'url': longUrl}));
      setState(() => loader = false);
      debugPrint('Shorten URL response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(response.body);
        final shortUrl = jsonResult['result_url'] as String;
        final uniquePart = shortUrl.split('/').last;
        return uniquePart;
      } else {
        debugPrint('Failed to shorten URL: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => loader = false);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${widget.type} Posts', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Expanded(
                child: ListView.separated(
                    itemCount: _getPostList(widget.type).length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final post = _getPostList(widget.type)[index];
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildContent(widget.type, post['content']!),
                        const SizedBox(height: 8),
                        ElevatedButton(
                            onPressed: () => _sharePost(context, widget.type, post['content']!),
                            child: const Text('Share'))
                      ]);
                    }))
          ])),
      if (loader) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator()))
    ]);
  }

  List<Map<String, String>> _getPostList(String type) {
    switch (type) {
      case 'Text':
        return _textPosts;
      case 'Video':
        return _videoPosts;
      case 'Image':
        return _imagePosts;
      default:
        return [];
    }
  }

  Widget _buildContent(String type, String content) {
    switch (type) {
      case 'Text':
        return Text(content);
      case 'Video':
        return AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(children: [
              Container(color: Colors.black),
              Center(
                  child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailPage(post: Post(type: 'Video', content: content)))),
                      child: const Text('Play')))
            ]));
      case 'Image':
        return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostDetailPage(post: Post(type: 'Image', content: content))));
            },
            child: Image.network(content, fit: BoxFit.fill,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                  child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null));
            }, width: 200, height: 200));
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _sharePost(BuildContext context, String type, String content) async {
    if (type != 'Text') {
      final shortUrlPart = await shortenUrl(content);
      if (shortUrlPart != null) {
        final link = 'https://deeplink-test-61cde.web.app/post/?type=$type&content=$shortUrlPart';
        Share.share(link);
      } else {
        debugPrint('Could not shorten the URL.');
      }
    } else {
      final link = 'https://deeplink-test-61cde.web.app/post/?type=$type';
      Share.share(link);
    }
  }
}
