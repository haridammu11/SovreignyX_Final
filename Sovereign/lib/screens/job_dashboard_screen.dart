import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/ats_colors.dart';
import 'post_job_screen.dart';
import 'applicant_review_screen.dart';

class JobDashboardScreen extends StatefulWidget {
  const JobDashboardScreen({super.key});

  @override
  State<JobDashboardScreen> createState() => _JobDashboardScreenState();
}

class _JobDashboardScreenState extends State<JobDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('jobs')
          .select('*, job_applications(count)')
          .eq('company_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading jobs: $e'),
            backgroundColor: ATSColors.danger,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: ATSColors.primary))
            : _jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: ATSColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            size: 80,
                            color: ATSColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Jobs Posted Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: ATSColors.neutral800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start hiring by creating your first job post',
                          style: TextStyle(
                            fontSize: 16,
                            color: ATSColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PostJobScreen()),
                            );
                            _fetchJobs();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ATSColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Post Your First Job',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    color: ATSColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) {
                        final job = _jobs[index];
                        final applicantCount = job['job_applications']?.length ?? 0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: ATSColors.neutral200, width: 1),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApplicantReviewScreen(job: job),
                                ),
                              );
                              _fetchJobs();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          job['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: ATSColors.neutral800,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ATSColors.successBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: ATSColors.success.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.people,
                                              size: 16,
                                              color: ATSColors.success,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$applicantCount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: ATSColors.successDark,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: ATSColors.neutral500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        job['location'] ?? 'Remote',
                                        style: TextStyle(
                                          color: ATSColors.neutral600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.work_outline,
                                        size: 16,
                                        color: ATSColors.neutral500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        job['type'] ?? 'Full-time',
                                        style: TextStyle(
                                          color: ATSColors.neutral600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (job['salary'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: ATSColors.neutral500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          job['salary'],
                                          style: TextStyle(
                                            color: ATSColors.neutral600,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Posted ${_formatDate(job['created_at'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ATSColors.neutral400,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: ATSColors.neutral400,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostJobScreen()),
              );
              _fetchJobs();
            },
            backgroundColor: ATSColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add),
            label: const Text(
              'Post Job',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return '${(diff.inDays / 30).floor()} months ago';
    } catch (e) {
      return 'recently';
    }
  }
}
