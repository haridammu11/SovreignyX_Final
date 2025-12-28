import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_reel_model.dart';
import '../services/course_reels_service.dart';
import '../services/supabase_service.dart';
import 'course_reels_screen.dart';

class ReelsHomeScreen extends StatefulWidget {
  const ReelsHomeScreen({Key? key}) : super(key: key);

  @override
  State<ReelsHomeScreen> createState() => _ReelsHomeScreenState();
}

class _ReelsHomeScreenState extends State<ReelsHomeScreen> {
  final CourseReelsService _reelsService = CourseReelsService();
  final SupabaseService _supabaseService = SupabaseService();

  List<CourseReel> _trendingReels = [];
  List<CourseReel> _personalizedReels = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      if (!_isRefreshing) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // Load trending reels
      final trending = await _reelsService.getTrendingReels(limit: 20);

      // Load personalized reels
      final userId = Supabase.instance.client.auth.currentUser?.id;
      List<CourseReel> personalized = [];
      if (userId != null) {
        personalized = await _reelsService.getPersonalizedReels(
          userId: userId,
          limit: 20,
        );
      } else {
        // If not logged in, show recent reels
        personalized = await _reelsService.getTrendingReels(limit: 20);
      }

      setState(() {
        _trendingReels = trending;
        _personalizedReels = personalized;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e, stackTrace) {
      print('Error loading reels: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load reels. Please try again.';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Reels'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReels, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshReels,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized section
              if (_personalizedReels.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'For You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to full personalized reels screen
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReelsGrid(_personalizedReels),
                const SizedBox(height: 32),
              ],

              // Trending section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full trending reels screen
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReelsGrid(_trendingReels),

              // Empty state for no reels
              if (_trendingReels.isEmpty && _personalizedReels.isEmpty) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'No reels available yet.\nCheck back later!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReelsGrid(List<CourseReel> reels) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        return _buildReelCard(reel);
      },
    );
  }

  Widget _buildReelCard(CourseReel reel) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CourseReelsScreen(
                  courseId: reel.courseId,
                  courseTitle: reel.courseTitle,
                ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder with play icon
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background with gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  // Play icon
                  const Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel.courseTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reel.language,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reel.likes}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
