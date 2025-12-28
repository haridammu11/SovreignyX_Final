import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_applications_screen.dart'; // Will implement next

class JobApplicationScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobApplicationScreen({super.key, required this.job});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverNoteController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume (PDF)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser!;
      final userId = user.id;
      final userEmail = user.email; // Snapshot
      // Ideally fetch name from 'users' table, assuming metadata or profile exists
      final userName = user.userMetadata?['first_name'] ?? 'Candidate';

      // 1. Upload Resume
      final fileExt = _selectedFile!.extension ?? 'pdf';
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName'; // Folder per user

      // For Web, use bytes, for Mobile use path
      if (_selectedFile!.bytes != null) {
         await _supabase.storage.from('resumes').uploadBinary(
          filePath,
          _selectedFile!.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else if (_selectedFile!.path != null) {
        final file = File(_selectedFile!.path!);
        await _supabase.storage.from('resumes').upload(
          filePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        throw Exception('File data unavailable');
      }

      final resumeUrl = _supabase.storage.from('resumes').getPublicUrl(filePath);

      // 2. Create Application Record
      await _supabase.from('job_applications').insert({
        'job_id': widget.job['id'],
        'student_id': userId,
        'student_name': userName,
        'student_email': userEmail,
        'resume_url': resumeUrl,
        'cover_note': _coverNoteController.text,
        'linkedin_url': _linkedinController.text,
        'github_url': _githubController.text,
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context); // Go back to Board
        // Optionally redirect to My Applications
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyApplicationsScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Apply to ${widget.job['title']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job specific info
              Text('Position: ${widget.job['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Resume Upload
              const Text('Resume (PDF)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickResume,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile != null ? _selectedFile!.name : 'Click to Upload Resume',
                          style: TextStyle(
                            color: _selectedFile != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (_selectedFile != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Links
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn Profile URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _githubController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Profile URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 24),

              // Cover Note
              TextFormField(
                controller: _coverNoteController,
                decoration: const InputDecoration(
                  labelText: 'Cover Note / Why you?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
