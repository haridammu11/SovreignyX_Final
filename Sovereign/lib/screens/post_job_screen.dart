import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/email_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _reqController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _jobType = 'Remote';
  bool _isLoading = false;

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Insert Job
      final response = await supabase.from('jobs').insert({
        'company_id': userId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'requirements': _reqController.text.trim(),
        'salary_range': _salaryController.text.trim(),
        'location': _locationController.text.trim(),
        'job_type': _jobType,
        'status': 'Open',
      }).select().single();

      // 2. Notify Students (Background)
      // We don't await this to keep UI responsive, or we show a separate "sending" status.
      // For now, we'll just fire and forget or let the service handle it.
      EmailService.notifyAllStudentsOfNewJob(
        jobTitle: _titleController.text,
        companyName: 'Company', // Ideally fetch company name
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post New Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Remote', 'Onsite', 'Hybrid']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _jobType = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reqController,
                decoration: const InputDecoration(
                  labelText: 'Requirements',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postJob,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
