import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/social.dart' as social;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/code_execution_service.dart';
import '../services/social_service.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;

  const ProfileScreen({super.key, required this.authService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isGeneratingPortfolio = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();
  final _projectsController = TextEditingController();
  final _certificatesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final SocialService _socialService = SocialService();
  List<social.Post> _userPosts = [];
  bool _isLoadingPosts = false;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isPrivateOption = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _projectsController.dispose();
    _certificatesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await widget.authService.getUserProfile();
      if (result['success']) {
        setState(() {
          _user = widget.authService.currentUser;
          _firstNameController.text = _user?.firstName ?? '';
          _lastNameController.text = _user?.lastName ?? '';
          final rawData = result['data'] as Map<String, dynamic>;
          _phoneController.text = rawData['phone'] as String? ?? '';
          _bioController.text = _user?.bio ?? '';
          _githubController.text = rawData['github_link'] as String? ?? '';
          _linkedinController.text = rawData['linkedin_link'] as String? ?? '';
          _portfolioController.text =
              rawData['portfolio_link'] as String? ?? '';
          _isPrivateOption = _user?.isPrivate ?? false;

          _isLoading = false;
        });
        _loadUserPosts();
        _loadSocialStats();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${result['error']}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _loadSocialStats() async {
    if (_user == null) return;
    try {
      final followers = await _socialService.getFollowers(_user!.id);
      final following = await _socialService.getFollowing(_user!.id);
      if (mounted) {
        setState(() {
          _followersCount = followers.length;
          _followingCount = following.length;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    if (_user == null) return;

    if (_user!.id.isEmpty) return;

    setState(() => _isLoadingPosts = true);

    try {
      final posts = await _socialService.getUserPosts(_user!.id);
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
        // ignore: avoid_print
        print('Error loading user posts: $e');
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await widget.authService.updateUserProfile(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          bio: _bioController.text,
          profilePicture: _profileImage,
          githubLink: _githubController.text,
          linkedinLink: _linkedinController.text,
          portfolioLink: _portfolioController.text,
          isPrivate: _isPrivateOption,
        );

        if (result['success']) {
          setState(() {
            _user = widget.authService.currentUser;
            _isEditing = false;
            _isLoading = false;
            _profileImage = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(width: 12),
                    const Text('Profile updated successfully'),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: ${result['error']}'),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _firstNameController.text = _user?.firstName ?? '';
        _lastNameController.text = _user?.lastName ?? '';
        _bioController.text = _user?.bio ?? '';
        _isPrivateOption = _user?.isPrivate ?? false;
        _profileImage = null;
      }
    });
  }

  Future<void> _generatePortfolio() async {
    setState(() {
      _isGeneratingPortfolio = true;
    });

    try {
      final codeService = CodeExecutionService();
      final result = await codeService.generatePortfolio(
        name: '${_firstNameController.text} ${_lastNameController.text}',
        bio: _bioController.text,
        skills: _skillsController.text,
        interests: _interestsController.text,
        projects: _projectsController.text,
        certificates: _certificatesController.text,
        socialLinks: {
          'github': _githubController.text,
          'linkedin': _linkedinController.text,
          'portfolio': _portfolioController.text,
        },
      );

      if (result['success'] == true) {
        final url = result['url'];
        if (mounted) {
          _showPortfolioSuccessDialog(url);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate: ${result['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPortfolio = false;
        });
      }
    }
  }

  void _showPortfolioSuccessDialog(String url) {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: cs.primary),
              const SizedBox(width: 12),
              const Text('Portfolio Live!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your portfolio website has been generated and is hosted at:',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outline.withOpacity(0.2)),
                ),
                child: SelectableText(url, style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch URL')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body:
          _isLoading && _user == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: CustomScrollView(
                  slivers: [
                    // Premium AppBar with Profile Header
                    SliverAppBar(
                      expandedHeight: 330,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      foregroundColor: cs.onPrimary,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.tertiary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [_buildProfileHeader()],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isEditing
                                ? Icons.close_rounded
                                : Icons.edit_rounded,
                          ),
                          onPressed: _toggleEdit,
                          tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
                        ),
                      ],
                    ),

                    // Tab Bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.person_rounded),
                              text: 'About',
                            ),
                            Tab(
                              icon: Icon(Icons.grid_on_rounded),
                              text: 'Content',
                            ),
                            Tab(
                              icon: Icon(Icons.article_rounded),
                              text: 'Posts',
                            ),
                          ],
                          labelColor: cs.primary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          indicatorColor: cs.primary,
                        ),
                      ),
                    ),

                    // Tab Content
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAboutTab(),
                          _buildContentTab(),
                          _buildPostsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton:
          _isEditing
              ? FloatingActionButton.extended(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Changes'),
              )
              : null,
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Determine text color based on gradient background (Primary/Tertiary usually bright in Cyberpunk theme)
    // Using onPrimary (Black) for high contrast on Electric Cyan.
    final headerTextColor = cs.onPrimary;
    final headerSubTextColor = cs.onPrimary.withOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onPrimary, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: cs.surfaceContainerHighest,
                  child:
                      _profileImage != null
                          ? CircleAvatar(
                            radius: 48,
                            backgroundImage: FileImage(_profileImage!),
                          )
                          : (_user?.profilePicture != null &&
                              _user!.profilePicture!.isNotEmpty)
                          ? CircleAvatar(
                            radius: 48,
                            backgroundImage: NetworkImage(
                              _user!.profilePicture!,
                            ),
                          )
                          : CircleAvatar(
                            radius: 48,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _user?.firstName?.isNotEmpty == true
                                  ? _user!.firstName!
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 32,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.onPrimary, width: 3),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: cs.onTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Name & Username
          Text(
            '${_user?.firstName ?? ''} ${_user?.lastName ?? ''}'.trim(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: headerTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '@${_user?.username ?? ''}',
                style: TextStyle(fontSize: 16, color: headerSubTextColor),
              ),
              if (_user?.isPrivate == true) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_rounded, size: 16, color: headerSubTextColor),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Posts', _userPosts.length, headerTextColor, headerSubTextColor),
              Container(height: 40, width: 1, color: headerSubTextColor.withOpacity(0.3)),
              _buildStatItem('Followers', _followersCount, headerTextColor, headerSubTextColor),
              Container(height: 40, width: 1, color: headerSubTextColor.withOpacity(0.3)),
              _buildStatItem('Following', _followingCount, headerTextColor, headerSubTextColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: subTextColor),
        ),
      ],
    );
  }

  Widget _buildAboutTab() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              Text(
                'Personal Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('First Name', _firstNameController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Last Name', _lastNameController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Phone', _phoneController),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                child: SwitchListTile(
                  title: const Text('Private Account'),
                  subtitle: const Text('Only followers can see your posts'),
                  value: _isPrivateOption,
                  onChanged: (val) => setState(() => _isPrivateOption = val),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bio Section
            Text(
              'Bio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),

            if (_isEditing)
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline_rounded),
                ),
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return 'Bio must be less than 200 characters';
                  }
                  return null;
                },
              )
            else
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _user?.bio?.isNotEmpty == true ? _user!.bio! : 'No bio yet',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Social Links
            Text(
              'Social Links',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),

            if (_isEditing) ...[
              _buildTextField('GitHub Profile URL', _githubController),
              const SizedBox(height: 12),
              _buildTextField('LinkedIn Profile URL', _linkedinController),
              const SizedBox(height: 12),
              _buildTextField('Portfolio / Website', _portfolioController),
              const SizedBox(height: 24),

              // Portfolio Generation Section
              Text(
                'Portfolio Generator',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField('Skills (comma separated)', _skillsController),
              const SizedBox(height: 12),
              _buildTextField(
                'Interests (comma separated)',
                _interestsController,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _projectsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notable Projects',
                  hintText: 'Describe projects not on GitHub...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _certificatesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Certificates & Achievements',
                  hintText: 'List your certifications, awards, etc...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isGeneratingPortfolio ? null : _generatePortfolio,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.purple,
                ),
                icon:
                    _isGeneratingPortfolio
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.web_rounded),
                label: Text(
                  _isGeneratingPortfolio
                      ? 'Generating...'
                      : 'Generate Portfolio Website',
                ),
              ),
            ] else ...[
              if (_githubController.text.isNotEmpty ||
                  _linkedinController.text.isNotEmpty ||
                  _portfolioController.text.isNotEmpty)
                Column(
                  children: [
                    _buildSocialLinkCard(
                      'GitHub',
                      _githubController.text,
                      Icons.code_rounded,
                      Colors.purple,
                    ),
                    _buildSocialLinkCard(
                      'LinkedIn',
                      _linkedinController.text,
                      Icons.business_rounded,
                      Colors.blue,
                    ),
                    _buildSocialLinkCard(
                      'Portfolio',
                      _portfolioController.text,
                      Icons.web_rounded,
                      Colors.orange,
                    ),
                  ],
                )
              else
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No social links added yet'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Content',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              FilledButton.tonalIcon(
                onPressed: _showCreateContentDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildContentCard(
                Icons.school_rounded,
                'Certificates',
                'View certificates',
                Colors.blue,
                () {
                  Navigator.pushNamed(
                    context,
                    '/certificates',
                    arguments: {
                      'userId': _user?.id ?? '',
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              _buildContentCard(
                Icons.description_rounded,
                'Resumes',
                'Manage resumes',
                Colors.green,
                () {},
              ),
              _buildContentCard(
                Icons.assignment_rounded,
                'Projects',
                'Your projects',
                Colors.orange,
                () {},
              ),
              _buildContentCard(
                Icons.emoji_events_rounded,
                'Achievements',
                'View achievements',
                Colors.purple,
                () {
                  Navigator.pushNamed(
                    context,
                    '/achievements',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              _buildContentCard(
                Icons.code_rounded,
                'Code Editor',
                'Practice coding',
                Colors.red,
                () {
                  Navigator.pushNamed(
                    context,
                    '/code-editor',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _isLoadingPosts
        ? const Center(child: CircularProgressIndicator())
        : _userPosts.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text('No posts yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Share your thoughts with the community!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/create-post',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Post'),
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _userPosts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(_userPosts[index]);
          },
        );
  }

  Widget _buildPostCard(social.Post post) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final timeAgo = DateTime.now().difference(post.createdAt);
    String timeString;
    if (timeAgo.inDays > 0) {
      timeString = '${timeAgo.inDays}d ago';
    } else if (timeAgo.inHours > 0) {
      timeString = '${timeAgo.inHours}h ago';
    } else {
      timeString = '${timeAgo.inMinutes}m ago';
    }

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.title != null) ...[
              Text(
                post.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(post.content, style: theme.textTheme.bodyMedium),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, o, s) => Container(
                        height: 200,
                        color: cs.surfaceContainer,
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == 'First Name' || label == 'Last Name') {
            return 'Please enter ${label.toLowerCase()}';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSocialLinkCard(
    String label,
    String url,
    IconData icon,
    Color color,
  ) {
    if (url.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: TextStyle(color: color, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateContentDialog() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Create New Content',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.blue),
                ),
                title: const Text('Certificate'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/certificates',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text('Resume'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Project'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    color: Colors.purple,
                  ),
                ),
                title: const Text('Post'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/create-post',
                    arguments: {
                      'userId': _user?.id ?? 1,
                      'token': widget.authService.token,
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
