import 'package:flutter/material.dart';
import '../models/social.dart';
import '../services/social_service.dart';

class SocialFeedScreen extends StatefulWidget {
  final String userId;
  final String? token;

  const SocialFeedScreen({super.key, required this.userId, this.token});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  late SocialService _socialService;
  List<Post> _posts = [];
  List<Achievement> _achievements = [];
  List<Leaderboard> _leaderboard = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socialService = SocialService(token: widget.token);
    _loadFeed();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SocialFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId && widget.userId.isNotEmpty) {
      print('SocialFeed: userId updated to ${widget.userId}. Reloading feed.');
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    if (widget.userId.isEmpty) {
      // Wait for parent to provide valid userId
      print('SocialFeed: Waiting for userId...');
      return;
    }

    try {
      print('SocialFeed: Loading posts...');
      final posts = await _socialService.getPosts();
      print('SocialFeed: Loaded ${posts.length} posts. Loading achievements...');
      
      final achievements = await _socialService.getAchievements(widget.userId);
      print('SocialFeed: Loaded ${achievements.length} achievements. Loading leaderboard...');
      
      final leaderboard = await _socialService.getLeaderboard();
      print('SocialFeed: Loaded leaderboard with ${leaderboard.length} entries.');

      if (mounted) {
        setState(() {
          _posts = posts;
          _achievements = achievements;
          _leaderboard = leaderboard;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('SocialFeed Error: $e');
      print('SocialFeed StackTrace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load feed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    try {
      await _socialService.createPost(
        authorId: widget.userId,
        content: _postController.text.trim(),
      );

      // Clear the input field
      _postController.clear();

      // Reload the feed
      _loadFeed();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create post: $e';
      });
    }
  }

  Future<void> _likePost(int postId) async {
    try {
      await _socialService.likePost(postId, widget.userId);
      // Reload the feed to show updated like count
      _loadFeed();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to like post: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Community Feed',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: cs.onSurface),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadFeed,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFeed,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Create post section
                        Card(
                          margin: const EdgeInsets.all(16),
                          color: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outline.withOpacity(0.1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _postController,
                                  maxLines: 3,
                                  style: TextStyle(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Share something with the community...',
                                    hintStyle:
                                        TextStyle(color: cs.onSurfaceVariant),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: cs.outline.withOpacity(0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: cs.outline.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: cs.primary),
                                    ),
                                    filled: true,
                                    fillColor: cs.surface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: _createPost,
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Post'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Achievements section
                        if (_achievements.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            color: cs.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.emoji_events,
                                          color: cs.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Your Achievements',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _achievements.length,
                                      itemBuilder: (context, index) {
                                        final achievement = _achievements[index];
                                        return Container(
                                          width: 120,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: cs.surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: cs.outline
                                                    .withOpacity(0.1)),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: cs.primaryContainer,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  achievement.icon != null
                                                      ? Icons.emoji_events
                                                      : Icons
                                                          .emoji_events_outlined,
                                                  color: cs.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                achievement.title,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Leaderboard section
                        if (_leaderboard.isNotEmpty)
                          Card(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            color: cs.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.leaderboard,
                                          color: cs.secondary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Top Learners',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _leaderboard.length > 3
                                        ? 3
                                        : _leaderboard.length,
                                    itemBuilder: (context, index) {
                                      final entry = _leaderboard[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: index == 0
                                              ? Colors.amber
                                              : index == 1
                                                  ? Colors.grey.shade400
                                                  : index == 2
                                                      ? Colors.brown.shade400
                                                      : cs.surfaceContainer,
                                          child: Text(
                                            '${entry.rank}',
                                            style: TextStyle(
                                              color: index < 3
                                                  ? Colors.black
                                                  : cs.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          (entry.firstName != null &&
                                                  entry.firstName!.isNotEmpty)
                                              ? '${entry.firstName} ${entry.lastName}'
                                                  .trim()
                                              : (entry.username != null &&
                                                      entry.username!
                                                          .isNotEmpty)
                                                  ? entry.username!
                                                  : 'User ${entry.userId}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${entry.points} pts',
                                            style: TextStyle(
                                              color: cs.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Posts feed
                        if (_posts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 48, color: cs.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No posts yet. Be the first to share!',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              final post = _posts[index];
                              return Card(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                color: cs.surfaceContainerHighest,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: cs.primaryContainer,
                                            backgroundImage:
                                                post.authorImage != null
                                                    ? NetworkImage(
                                                        post.authorImage!)
                                                    : null,
                                            child: post.authorImage == null
                                                ? Text(
                                                    (post.authorName != null &&
                                                            post.authorName!
                                                                .isNotEmpty)
                                                        ? post.authorName![0]
                                                            .toUpperCase()
                                                        : post.authorId
                                                            .toString()[0]
                                                            .toUpperCase(),
                                                    style: TextStyle(
                                                      color:
                                                          cs.onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.authorName ??
                                                    'User ${post.authorId}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.onSurface,
                                                ),
                                              ),
                                              Text(
                                                '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                                style: TextStyle(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        post.content,
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontSize: 15,
                                        ),
                                      ),
                                      // Display post image if available
                                      if (post.imageUrl != null &&
                                          post.imageUrl!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              post.imageUrl!,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 200,
                                                  color: cs.surface,
                                                  child: Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          color: cs
                                                              .onSurfaceVariant)),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.favorite_border),
                                            color: cs.onSurfaceVariant,
                                            onPressed: () =>
                                                _likePost(post.id),
                                          ),
                                          Text(
                                            '${post.likesCount}',
                                            style: TextStyle(
                                                color: cs.onSurfaceVariant),
                                          ),
                                          const SizedBox(width: 16),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.comment_outlined),
                                            color: cs.onSurfaceVariant,
                                            onPressed: () {
                                              // Handle comment
                                            },
                                          ),
                                          Text(
                                            '${post.commentsCount}',
                                            style: TextStyle(
                                                color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'social_feed_fab',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () async {
          // Navigate to create post screen
          final result = await Navigator.pushNamed(
            context,
            '/create-post',
            arguments: {'userId': widget.userId, 'token': widget.token},
          );

          if (result == true) {
            _loadFeed();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
