import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/youtube_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final YouTubeService _service = YouTubeService();
  final PageController _pageController = PageController();
  List<String> _videoIds = [];
  bool _isLoading = true;
  String _currentQuery = 'Programming';
  
  @override
  void initState() {
    super.initState();
    _loadVideos();
  }
  
  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final ids = await _service.searchShorts(_currentQuery);
    if (mounted) {
      if (ids.isEmpty && _videoIds.isEmpty) {
        // Fallback demo if valid key search fails or empty
        // Actually YouTubeService fallback logic handles key missing. 
        // If query returns 0 items, we just show empty.
      }
      
      setState(() {
        _videoIds = ids;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _videoIds.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const Icon(Icons.error_outline, size: 50, color: Colors.white),
                     const SizedBox(height: 10),
                     Text('No reels found for "$_currentQuery"', style: const TextStyle(color: Colors.white)),
                     const Text('Hint: Add a YouTube API Key in Constants', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: _videoIds.length,
                  itemBuilder: (context, index) {
                    return ReelPlayerItem(
                      key: ValueKey(_videoIds[index]), // Key ensures proper rebuild
                      videoId: _videoIds[index]
                    );
                  },
                ),
          
          // Top Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                       filled: true,
                       fillColor: Colors.black54,
                       hintText: 'Search topic (e.g. Flutter)',
                       hintStyle: const TextStyle(color: Colors.white70),
                       prefixIcon: const Icon(Icons.search, color: Colors.white),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (val) {
                       if(val.isNotEmpty) {
                         setState(() {
                           _currentQuery = val;
                           _pageController.jumpToPage(0);
                         });
                         _loadVideos();
                       }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ReelPlayerItem extends StatefulWidget {
  final String videoId;
  const ReelPlayerItem({super.key, required this.videoId});
  
  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> with AutomaticKeepAliveClientMixin {
  late YoutubePlayerController _controller;
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true; // Keep state to avoid reloading on minor scrolls

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: true,
        enableCaption: false,
      ),
    )..addListener(() {
      if(mounted) setState((){});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
       color: Colors.black,
       child: Stack(
         alignment: Alignment.center,
         children: [
           Center(
             child: AspectRatio(
               aspectRatio: 9 / 16, // Reels Aspect Ratio
               child: YoutubePlayer(
                 controller: _controller,
                 showVideoProgressIndicator: true,
                 progressIndicatorColor: Colors.red,
               ),
             ),
           ),
           if (!_controller.value.isPlaying)
              const Icon(Icons.play_arrow, size: 60, color: Colors.white54),
         ],
       )
    );
  }
}
