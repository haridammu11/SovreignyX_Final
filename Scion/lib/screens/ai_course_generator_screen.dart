import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_course_service.dart';
import '../services/youtube_service.dart';

class AICourseGeneratorScreen extends StatefulWidget {
  const AICourseGeneratorScreen({super.key});

  @override
  State<AICourseGeneratorScreen> createState() =>
      _AICourseGeneratorScreenState();
}

class _AICourseGeneratorScreenState extends State<AICourseGeneratorScreen>
    with TickerProviderStateMixin {
  final _topicController = TextEditingController();
  final _service = AICourseService();
  final _ytService = YouTubeService();
  late AnimationController _generateButtonController;
  late AnimationController _cardAnimationController;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _generatedCourse;

  @override
  void initState() {
    super.initState();
    _generateButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _generateButtonController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _generateCourse() async {
    if (_topicController.text.isEmpty) return;

    _generateButtonController.forward().then(
      (_) => _generateButtonController.reverse(),
    );
    setState(() => _isLoading = true);

    try {
      final result = await _service.generateCourseOutline(
        _topicController.text,
      );
      if (mounted) {
        setState(() {
          _generatedCourse = result;
          _isLoading = false;
        });
        _cardAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
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
  }

  Future<void> _saveAndEnroll() async {
    if (_generatedCourse == null) return;

    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      final courseRes =
          await client
              .from('courses')
              .insert({
                'title': _generatedCourse!['title'],
                'description': _generatedCourse!['description'],
                'thumbnail_url':
                    'https://via.placeholder.com/300x200.png?text=AI+Course',
              })
              .select()
              .single();

      final courseId = courseRes['id'];

      final modules = _generatedCourse!['modules'] as List;
      for (int i = 0; i < modules.length; i++) {
        final mod = modules[i];
        final modRes =
            await client
                .from('modules')
                .insert({
                  'course_id': courseId,
                  'title': mod['title'],
                  'order_index': i,
                })
                .select()
                .single();

        final lessons = mod['lessons'] as List;
        for (int j = 0; j < lessons.length; j++) {
          final lesson = lessons[j];

          String videoId = 'fT2KhJ8W-Kg';
          final query =
              lesson['search_query'] ??
              '${lesson['title']} ${mod['title']} tutorial';
          final foundId = await _ytService.searchLongVideo(query);
          if (foundId != null) videoId = foundId;

          String fullDesc = lesson['description'] ?? '';
          if (lesson['resources'] != null &&
              (lesson['resources'] as List).isNotEmpty) {
            fullDesc += '\n\n**Resources:**\n';
            for (var r in (lesson['resources'] as List)) {
              fullDesc += '${r['title']} | ${r['url']}\n';
            }
          }

          await client.from('lessons').insert({
            'module_id': modRes['id'],
            'title': lesson['title'],
            'description': fullDesc,
            'video_url': 'https://www.youtube.com/watch?v=$videoId',
            'order_index': j,
            'duration_seconds': 600,
          });
        }
      }

      await client.from('enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Course Created & Enrolled!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/course-detail',
          arguments: {'courseId': courseId, 'courseTitle': courseRes['title']},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Save Error: $e')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.pink.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Course Generator',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                Theme.of(context).colorScheme.primary,
                Colors.purple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade100,
                                  Colors.pink.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What do you want to learn?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'AI will create a personalized course',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _topicController,
                        decoration: InputDecoration(
                          labelText: 'Enter Topic',
                          hintText: 'e.g., Flutter for Beginners',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: const Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                          CurvedAnimation(
                            parent: _generateButtonController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateCourse,
                            icon:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.auto_awesome),
                            label: Text(
                              _isLoading
                                  ? 'Generating...'
                                  : 'Generate Course Outline',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Generated Course Section
                if (_generatedCourse != null)
                  Expanded(
                    child: FadeTransition(
                      opacity: _cardAnimationController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _cardAnimationController,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Course Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.shade600,
                                      Colors.pink.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.school,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _generatedCourse!['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${(_generatedCourse!['modules'] as List).length} Modules',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _generatedCourse!['description'],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Modules List
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    (_generatedCourse!['modules'] as List)
                                        .length,
                                itemBuilder: (context, index) {
                                  final mod =
                                      (_generatedCourse!['modules']
                                          as List)[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.purple.shade100,
                                                Colors.pink.shade100,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade700,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          mod['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${(mod['lessons'] as List).length} lessons',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        children:
                                            (mod['lessons'] as List).map<
                                              Widget
                                            >((l) {
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: ListTile(
                                                  leading: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.purple.shade50,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.play_circle_outline,
                                                      color:
                                                          Colors
                                                              .purple
                                                              .shade600,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    l['title'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    l['description'],
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Create Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade600,
                                      Colors.green.shade700,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    icon:
                                        _isSaving
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Icon(Icons.rocket_launch),
                                    label: Text(
                                      _isSaving
                                          ? 'Creating Course...'
                                          : 'Create & Enroll Now',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed:
                                        (_isLoading || _isSaving)
                                            ? null
                                            : _saveAndEnroll,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
