import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'job_application_screen.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('jobs')
          .select('*, companies(name, email)') // Join with companies
          .eq('status', 'Open');

      if (_filterType != null) {
        query = query.eq('job_type', _filterType!);
      }

      // Apply ordering at the end, as it returns a TransformBuilder
      final response = await query.order('created_at', ascending: false);
      setState(() {
        _jobs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // Handle error quietly or show snackbar
        debugPrint('Error fetching jobs: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value == 'All' ? null : value;
              });
              _fetchJobs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              const PopupMenuItem(value: 'Remote', child: Text('Remote')),
              const PopupMenuItem(value: 'Onsite', child: Text('Onsite')),
              const PopupMenuItem(value: 'Hybrid', child: Text('Hybrid')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text('No open jobs found matching your criteria.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];
                    final companyName = job['companies']?['name'] ?? 'Unknown Company';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    job['job_type'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  job['location'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  job['salary_range'] ?? 'Negotiable',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobApplicationScreen(job: job),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Apply Now'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
