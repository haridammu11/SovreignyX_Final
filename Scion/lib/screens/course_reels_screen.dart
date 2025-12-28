import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_reel_model.dart';
import '../services/supabase_service.dart';
import '../services/course_reels_service.dart';
import '../utils/constants.dart';

class CourseReelsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseReelsScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<CourseReelsScreen> createState() => _CourseReelsScreenState();
}

class _CourseReelsScreenState extends State<CourseReelsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final PageController _pageController = PageController();
  final CourseReelsService _reelsService = CourseReelsService();

  List<CourseReel> _reels = [];
  List<String> _availableLanguages = [
    'English',
    'Telugu',
    'Hindi',
    'Tamil',
    'Kannada',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];
  String _selectedLanguage = 'English';
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _initialPopulationDone = false;
  String _errorMessage = '';
  Map<String, bool> _likedReels = {};
  Map<String, YoutubePlayerController?> _controllers = {};
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadReels();
  }

  /// ULTRA-STRICT Load reels for this course with enhanced error handling
  Future<void> _loadReels() async {
    try {
      print(
        '🔍 Loading reels for course: ${widget.courseTitle} in ${_selectedLanguage}',
      );
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get reels from database with enhanced filtering
      var reelsData = await _supabaseService.getCourseReels(
        courseId: widget.courseId,
        language: _selectedLanguage,
      );

      print('📊 Retrieved ${reelsData.length} raw reels from database');

      // If no reels found and we haven't tried to populate yet, do it now
      if (reelsData.isEmpty && !_initialPopulationDone) {
        print(
          '🔴 No reels found for ${widget.courseTitle} in ${_selectedLanguage}, attempting to populate...',
        );
        await _populateReelsIfNeeded();
        _initialPopulationDone = true;

        // Try loading again after population
        print('🔍 Reloading reels after population attempt');
        final retryReelsData = await _supabaseService.getCourseReels(
          courseId: widget.courseId,
          language: _selectedLanguage,
        );

        print('📊 Retrieved ${retryReelsData.length} reels after population');
        // Add the retry data to the original list
        reelsData.addAll(retryReelsData);
      }

      // Convert dynamic list to CourseReel list with ULTRA-STRICT validation
      final reels = <CourseReel>[];
      for (var data in reelsData) {
        try {
          final reelData = data as Map<String, dynamic>;

          // ULTRA-STRICT: Validate that the reel is actually for this course and language
          final reelCourseTitle = reelData['course_title'] as String? ?? '';
          final reelLanguage = reelData['language'] as String? ?? 'English';

          // Only include reels that match our current course and language EXACTLY
          if (reelCourseTitle.toLowerCase() ==
                  widget.courseTitle.toLowerCase() &&
              reelLanguage.toLowerCase() == _selectedLanguage.toLowerCase()) {
            reels.add(CourseReel.fromJson(reelData));
          } else {
            print(
              '🟡 Skipping reel for different course/language: ${reelCourseTitle} (${reelLanguage})',
            );
          }
        } catch (e) {
          print('❌ Error parsing reel data: $e');
        }
      }

      print('✅ Validated and filtered to ${reels.length} relevant reels');

      // Load user's liked reels
      final likedReelsIds = await _supabaseService.getUserLikedReels();
      final likedMap = <String, bool>{};
      for (var reelId in likedReelsIds) {
        likedMap[reelId] = true;
      }

      // Initialize controllers for each reel
      _controllers.clear();
      for (var reel in reels) {
        try {
          _controllers[reel.id] = YoutubePlayerController(
            initialVideoId: reel.videoId,
            flags: const YoutubePlayerFlags(
              mute: false,
              autoPlay: true,
              hideControls: true,
              disableDragSeek: true,
              loop: false,
              isLive: false,
              forceHD: false,
              enableCaption: false,
            ),
          );
        } catch (e) {
          print('Error initializing controller for reel ${reel.id}: $e');
          _controllers[reel.id] = null;
        }
      }

      setState(() {
        _reels = reels;
        _likedReels = likedMap;
        _isLoading = false;
      });

      print(
        '🎉 Successfully loaded ${reels.length} reels for ${widget.courseTitle}',
      );
    } catch (e, stackTrace) {
      print('❌ Error loading reels: $e');
      print('📝 Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load reels: $e';
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(CourseReel reel) async {
    try {
      final isCurrentlyLiked = _likedReels[reel.id] ?? false;

      // Trigger animation
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });

      if (isCurrentlyLiked) {
        await _supabaseService.unlikeReel(reelId: reel.id);
        setState(() {
          _likedReels[reel.id] = false;
          // Update the reel's like count
          final index = _reels.indexWhere((r) => r.id == reel.id);
          if (index != -1) {
            _reels[index] = CourseReel(
              id: _reels[index].id,
              courseId: _reels[index].courseId,
              courseTitle: _reels[index].courseTitle,
              videoId: _reels[index].videoId,
              title: _reels[index].title,
              description: _reels[index].description,
              language: _reels[index].language,
              likes: _reels[index].likes > 0 ? _reels[index].likes - 1 : 0,
              createdAt: _reels[index].createdAt,
            );
          }
        });
      } else {
        await _supabaseService.likeReel(
          reelId: reel.id,
          courseId: reel.courseId,
          language: reel.language,
        );
        setState(() {
          _likedReels[reel.id] = true;
          // Update the reel's like count
          final index = _reels.indexWhere((r) => r.id == reel.id);
          if (index != -1) {
            _reels[index] = CourseReel(
              id: _reels[index].id,
              courseId: _reels[index].courseId,
              courseTitle: _reels[index].courseTitle,
              videoId: _reels[index].videoId,
              title: _reels[index].title,
              description: _reels[index].description,
              language: _reels[index].language,
              likes: _reels[index].likes + 1,
              createdAt: _reels[index].createdAt,
            );
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to update like: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      _loadReels();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _controllers.values.forEach((controller) {
      controller?.dispose();
    });
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.courseTitle}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.play_circle_filled, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${_reels.length} Reels',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade700.withOpacity(0.9),
                Colors.pink.shade600.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Manual reel addition button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAddReelDialog,
              tooltip: 'Add Reel',
            ),
          ),
          // Language selector dropdown
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.purple.shade700,
              underline: Container(),
              icon: const Icon(Icons.language, color: Colors.white, size: 18),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items:
                  _availableLanguages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
              onChanged: _onLanguageChanged,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.pink.withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading Reels...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.pink.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loadReels,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_reels.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Reels Available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'No reels found for $_selectedLanguage',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.pink.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _populateReelsIfNeeded,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Generate Reels',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _reels.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;

          // Pause all videos except the current one
          for (int i = 0; i < _reels.length; i++) {
            final controller = _controllers[_reels[i].id];
            if (controller != null) {
              if (i == index) {
                controller.play();
              } else {
                controller.pause();
              }
            }
          }
        });
      },
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return _buildReelItem(reel);
      },
    );
  }

  Widget _buildReelItem(CourseReel reel) {
    final isLiked = _likedReels[reel.id] ?? false;
    final controller = _controllers[reel.id];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player or fallback
        _buildVideoPlayer(reel, controller),

        // Overlay UI with glassmorphism
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with gradient
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.pink.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reel.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reel.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    // Animated Like button
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                        CurvedAnimation(
                          parent: _likeAnimationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => _toggleLike(reel),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isLiked
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLiked ? Colors.red : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${reel.likes}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Language tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.6),
                            Colors.pink.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reel.language,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // External link button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          final url =
                              'https://www.youtube.com/watch?v=${reel.videoId}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Enhanced progress indicator
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_reels.length, (index) {
              final isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient:
                      isActive
                          ? LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.pink.shade400,
                            ],
                          )
                          : null,
                  color: isActive ? null : Colors.white.withOpacity(0.5),
                  boxShadow:
                      isActive
                          ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(
    CourseReel reel,
    YoutubePlayerController? controller,
  ) {
    if (controller == null) {
      // Fallback UI when controller fails to initialize
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load video',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final url = 'https://www.youtube.com/watch?v=${reel.videoId}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              },
              child: const Text(
                'Open in YouTube',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    try {
      return YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: false,
        onEnded: (metaData) {
          // Auto-play next video when current one ends
          if (_currentIndex < _reels.length - 1) {
            _pageController.animateToPage(
              _currentIndex + 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
      );
    } catch (e) {
      print('Error building video player: $e');
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 48),
        ),
      );
    }
  }

  /// ULTRA-STRICT Populate reels for this course if none exist
  /// This method ensures ONLY the EXACT course reels are populated
  Future<void> _populateReelsIfNeeded() async {
    try {
      print(
        '🔴 ULTRA-STRICT Attempting to populate reels for course: ${widget.courseTitle} in ${_selectedLanguage}',
      );

      // Call the populate method with enhanced retry logic
      int attempts = 0;
      bool success = false;

      while (attempts < 5 && !success) {
        // Increased to 5 attempts
        try {
          await _reelsService.populateCourseReels(
            courseId: widget.courseId,
            courseTitle: widget.courseTitle,
            language: _selectedLanguage,
          );
          success = true;
        } catch (e) {
          attempts++;
          print('🔴 Attempt $attempts failed: $e');
          if (attempts < 5) {
            // Exponential backoff
            await Future.delayed(Duration(seconds: 2 * attempts));
          }
        }
      }

      if (success) {
        print('✅ Reels populated successfully after $attempts attempt(s)');
      } else {
        print('❌ Failed to populate reels after 5 attempts');
        // Even if population failed, try to load whatever reels might exist
        await _loadReels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to populate reels for this course. Showing existing content.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Reload reels after population
      await _loadReels();

      // Show success message
      if (mounted && _reels.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully loaded ${_reels.length} relevant reels for ${widget.courseTitle}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error populating reels: $e');
      // Show user-friendly error message but still try to load existing reels
      await _loadReels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error occurred while loading reels. Showing available content.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Show dialog to add a manual reel
  void _showAddReelDialog() {
    final videoIdController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Manual Reel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: videoIdController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube Video ID',
                    hintText: 'Enter YouTube video ID',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter reel title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter reel description',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (videoIdController.text.isNotEmpty &&
                    titleController.text.isNotEmpty) {
                  Navigator.of(context).pop();

                  try {
                    await _reelsService.addManualReel(
                      courseId: widget.courseId,
                      courseTitle: widget.courseTitle,
                      videoId: videoIdController.text.trim(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      language: _selectedLanguage,
                    );

                    // Refresh the reels list
                    await _loadReels();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reel added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add reel: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add Reel'),
            ),
          ],
        );
      },
    );
  }
}
