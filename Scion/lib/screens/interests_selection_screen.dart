import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsSelectionScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const InterestsSelectionScreen({
    super.key,
    this.isFirstTime = true,
  });

  @override
  State<InterestsSelectionScreen> createState() => _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedInterests = {};
  String _searchQuery = '';
  bool _isLoading = false;

  // Interest categories by engineering stream
  final Map<String, List<String>> _interestsByStream = {
    'Computer Engineering': [
      'Artificial Intelligence',
      'Machine Learning',
      'Web Development',
      'Mobile Development',
      'Cybersecurity',
      'Cloud Computing',
      'Data Science',
      'Blockchain',
      'IoT (Internet of Things)',
      'Game Development',
      'DevOps',
      'Computer Vision',
      'Natural Language Processing',
      'Software Architecture',
    ],
    'Mechanical Engineering': [
      'Thermodynamics',
      'Fluid Mechanics',
      'CAD/CAM',
      'Robotics',
      'Manufacturing',
      'Automotive Engineering',
      'HVAC Systems',
      'Materials Science',
      'Mechatronics',
      'Aerospace Dynamics',
      '3D Printing',
      'Energy Systems',
    ],
    'Civil Engineering': [
      'Structural Design',
      'Geotechnical Engineering',
      'Transportation Engineering',
      'Environmental Engineering',
      'Construction Management',
      'Hydraulics',
      'Urban Planning',
      'Earthquake Engineering',
      'Bridge Design',
      'Sustainable Construction',
    ],
    'Electrical Engineering': [
      'Power Systems',
      'Control Systems',
      'Signal Processing',
      'Embedded Systems',
      'Telecommunications',
      'Renewable Energy',
      'Circuit Design',
      'Microelectronics',
      'Power Electronics',
      'Instrumentation',
    ],
    'Electronics Engineering': [
      'VLSI Design',
      'Digital Electronics',
      'Analog Electronics',
      'Communication Systems',
      'Microprocessors',
      'Embedded Systems',
      'Signal Processing',
      'RF Engineering',
      'IoT Electronics',
    ],
    'Chemical Engineering': [
      'Process Engineering',
      'Biochemical Engineering',
      'Polymer Engineering',
      'Environmental Chemistry',
      'Petrochemical Engineering',
      'Pharmaceutical Engineering',
      'Food Processing',
      'Nanotechnology',
    ],
    'Aerospace Engineering': [
      'Aerodynamics',
      'Aircraft Design',
      'Propulsion Systems',
      'Flight Mechanics',
      'Space Systems',
      'Avionics',
      'Composite Materials',
      'Satellite Technology',
    ],
    'Biomedical Engineering': [
      'Medical Imaging',
      'Biomechanics',
      'Prosthetics',
      'Tissue Engineering',
      'Medical Devices',
      'Bioinformatics',
      'Rehabilitation Engineering',
      'Biosensors',
    ],
    'Environmental Engineering': [
      'Water Treatment',
      'Air Quality Management',
      'Waste Management',
      'Sustainable Development',
      'Environmental Impact Assessment',
      'Green Technology',
      'Climate Change',
    ],
    'Industrial Engineering': [
      'Operations Research',
      'Supply Chain Management',
      'Quality Control',
      'Lean Manufacturing',
      'Six Sigma',
      'Production Planning',
      'Ergonomics',
      'Logistics',
    ],
  };

  List<String> get _allInterests {
    final allInterests = <String>[];
    _interestsByStream.forEach((stream, interests) {
      allInterests.addAll(interests);
    });
    return allInterests.toSet().toList()..sort();
  }

  List<String> get _filteredInterests {
    if (_searchQuery.isEmpty) return _allInterests;
    return _allInterests
        .where((interest) =>
            interest.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _saveInterests() async {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // Delete existing interests
      await Supabase.instance.client
          .from('student_interests')
          .delete()
          .eq('student_email', user.email!);

      // Insert new interests
      final interests = _selectedInterests.map((interest) {
        return {
          'student_email': user.email,
          'interest_category': interest,
        };
      }).toList();

      await Supabase.instance.client
          .from('student_interests')
          .insert(interests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interests saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isFirstTime) {
          // Navigate to dashboard on first-time setup
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          // Just go back if editing from profile
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Interests'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.purple.shade700,
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Colors.purple.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.interests,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isFirstTime
                      ? 'Tell us what you\'re interested in!'
                      : 'Update Your Interests',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select at least 3 areas to get personalized course recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Selected count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedInterests.length >= 3
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedInterests.length >= 3
                            ? Icons.check_circle
                            : Icons.info,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedInterests.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search interests...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Interests Grid
          Expanded(
            child: _filteredInterests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No interests found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _interestsByStream.entries.map((entry) {
                      final stream = entry.key;
                      final interests = entry.value
                          .where((interest) =>
                              _searchQuery.isEmpty ||
                              interest
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()))
                          .toList();

                      if (interests.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  stream,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.map((interest) {
                              final isSelected =
                                  _selectedInterests.contains(interest);
                              return FilterChip(
                                label: Text(interest),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedInterests.add(interest);
                                    } else {
                                      _selectedInterests.remove(interest);
                                    }
                                  });
                                },
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                checkmarkColor:
                                    Theme.of(context).colorScheme.primary,
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveInterests,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Interests (${_selectedInterests.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
