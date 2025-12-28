import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('job_applications')
          .select('*, jobs(title, companies(name))')
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading applications: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'reviewing': return Colors.blue;
      case 'interview': return Colors.purple;
      case 'offer': return Colors.green;
      case 'accepted': return Colors.green.shade800;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('You haven\'t applied to any jobs yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    final jobTitle = app['jobs']['title'];
                    final companyName = app['jobs']['companies']['name'];
                    final status = app['status'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.work, color: Colors.blue),
                        ),
                        title: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(companyName),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
