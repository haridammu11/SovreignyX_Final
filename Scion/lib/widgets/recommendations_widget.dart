import 'package:flutter/material.dart';
import '../services/course_recommendation_service.dart';
import '../services/student_interests_service.dart';

class RecommendationsWidget extends StatefulWidget {
  const RecommendationsWidget({super.key});

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  final CourseRecommendationService _recommendationService =
      CourseRecommendationService();
  final StudentInterestsService _interestsService = StudentInterestsService();

  List<Map<String, dynamic>> _recommendations = [];
  List<String> _studentInterests = [];
  bool _isLoading = true;
  String? _selectedInterestFilter;
  String? _selectedDifficultyFilter;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Load student interests
      final interests = await _interestsService.getStudentInterests();
      
      // Load recommendations
      final recommendations = await _recommendationService.getRecommendations(
        limit: 10,
        filterByInterest: _selectedInterestFilter,
        difficulty: _selectedDifficultyFilter,
      );

      setState(() {
        _studentInterests = interests;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_studentInterests.isEmpty) {
      return _buildSetupInterestsPrompt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.recommend,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Based on: ${_studentInterests.take(3).join(", ")}${_studentInterests.length > 3 ? "..." : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Interest Filter
              FilterChip(
                label: Text(_selectedInterestFilter ?? 'All Interests'),
                selected: _selectedInterestFilter != null,
                onSelected: (selected) {
                  _showInterestFilterDialog();
                },
                avatar: const Icon(Icons.filter_list, size: 18),
              ),
              const SizedBox(width: 8),
              
              // Difficulty Filter
              FilterChip(
                label: Text(_selectedDifficultyFilter ?? 'All Levels'),
                selected: _selectedDifficultyFilter != null,
                onSelected: (selected) {
                  _showDifficultyFilterDialog();
                },
                avatar: const Icon(Icons.signal_cellular_alt, size: 18),
              ),
              const SizedBox(width: 8),
              
              // Clear Filters
              if (_selectedInterestFilter != null ||
                  _selectedDifficultyFilter != null)
                ActionChip(
                  label: const Text('Clear'),
                  avatar: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedInterestFilter = null;
                      _selectedDifficultyFilter = null;
                    });
                    _loadRecommendations();
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recommendations List
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : _recommendations.isEmpty
                ? _buildNoRecommendations()
                : SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final course = _recommendations[index];
                        return _buildRecommendationCard(course);
                      },
                    ),
                  ),

        // See All Button
        if (_recommendations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/courses');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('See All Recommendations'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> course) {
    final matchPercentage = course['match_percentage'] as int? ?? 0;
    final matchingInterests = course['matching_interests'] as int? ?? 0;
    final rating = (course['rating'] as num?)?.toDouble() ?? 0.0;
    final company = course['companies'] as Map<String, dynamic>?;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/course-detail',
              arguments: {
                'courseId': course['id'],
                'courseTitle': course['title'],
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: matchPercentage >= 70
                              ? [Colors.green, Colors.green.shade700]
                              : matchPercentage >= 50
                                  ? [Colors.orange, Colors.orange.shade700]
                                  : [Colors.blue, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchPercentage% Match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Course Title
                Text(
                  course['title'] as String? ?? 'Untitled Course',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Course Description
                Text(
                  course['description'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Company Info
                if (company != null) ...[
                  const Divider(),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          company['name'] as String? ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Matching Interests
                if (matchingInterests > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$matchingInterests matching interest${matchingInterests > 1 ? "s" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupInterestsPrompt() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.interests,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Get Personalized Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us your interests to see courses tailored just for you!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/interests-selection');
            },
            icon: const Icon(Icons.add),
            label: const Text('Set Up Interests'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecommendations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Recommendations Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or explore all courses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInterestFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Interest'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Interests'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedInterestFilter,
                  onChanged: (value) {
                    setState(() => _selectedInterestFilter = value);
                    Navigator.pop(context);
                    _loadRecommendations();
                  },
                ),
              ),
              ..._studentInterests.map((interest) {
                return ListTile(
                  title: Text(interest),
                  leading: Radio<String?>(
                    value: interest,
                    groupValue: _selectedInterestFilter,
                    onChanged: (value) {
                      setState(() => _selectedInterestFilter = value);
                      Navigator.pop(context);
                      _loadRecommendations();
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyFilterDialog() {
    final difficulties = ['Beginner', 'Intermediate', 'Advanced'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Levels'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedDifficultyFilter,
                onChanged: (value) {
                  setState(() => _selectedDifficultyFilter = value);
                  Navigator.pop(context);
                  _loadRecommendations();
                },
              ),
            ),
            ...difficulties.map((difficulty) {
              return ListTile(
                title: Text(difficulty),
                leading: Radio<String?>(
                  value: difficulty,
                  groupValue: _selectedDifficultyFilter,
                  onChanged: (value) {
                    setState(() => _selectedDifficultyFilter = value);
                    Navigator.pop(context);
                    _loadRecommendations();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
