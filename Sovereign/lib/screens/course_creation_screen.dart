import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_course_service.dart';
import '../services/course_service.dart';

class CourseCreationScreen extends StatefulWidget {
  const CourseCreationScreen({super.key});

  @override
  State<CourseCreationScreen> createState() => _CourseCreationScreenState();
}

class _CourseCreationScreenState extends State<CourseCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _moduleCountController = TextEditingController(text: '10');
  final _pointsController = TextEditingController(text: '50');
  
  bool _isGenerating = false;
  bool _isSaving = false;
  List<ModuleData> _generatedModules = [];
  String? _companyStream;
  
  // Service instances
  final _courseService = CourseService();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCompanyDetails();
  }

  Future<void> _fetchCompanyDetails() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('companies')
            .select('engineering_stream')
            .eq('id', user.id)
            .maybeSingle(); // Use maybeSingle to avoid crash if not found
            
        if (response != null && mounted) {
           setState(() {
             _companyStream = response['engineering_stream'] as String?;
           });
        }
      }
    } catch (e) {
      debugPrint('Error fetching company details: $e');
    }
  }

  Future<void> _generateStructure() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final modules = await AiCourseService.generateModules(
        _courseNameController.text, 
        int.parse(_moduleCountController.text)
      );
      
      setState(() {
        _generatedModules = modules.map((title) => ModuleData(title: title)).toList();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${modules.length} modules!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateDescriptionForModule(int index) async {
    final module = _generatedModules[index];
    setState(() => module.isGeneratingDesc = true);
    
    try {
      final desc = await AiCourseService.generateVideoDescription(
        _courseNameController.text, 
        module.title
      );
      
      setState(() {
        module.descriptionController.text = desc;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating description: $e')),
      );
    } finally {
      setState(() => module.isGeneratingDesc = false);
    }
  }

  Future<void> _publishCourse() async {
    if (_generatedModules.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    try {
      // 1. Create Course
      final courseId = await _courseService.createCourse(
        _courseNameController.text,
        'AI Generated Course including ${_generatedModules.length} modules.',
        _companyStream ?? 'Computer Engineering', // Fallback or require it
        _supabase.auth.currentUser?.email,
        points: int.tryParse(_pointsController.text) ?? 50,
      );
      
      // 2. Create Modules and Lessons
      for (int i = 0; i < _generatedModules.length; i++) {
        final moduleData = _generatedModules[i];
        
        // Create Module
        final moduleId = await _courseService.createModule(
          courseId, 
          moduleData.title, 
          i + 1 // order
        );
        
        // Create Lesson (Video) for this module
        if (moduleData.youtubeUrlController.text.isNotEmpty) {
           await _courseService.createLesson(
             moduleId,
             moduleData.title, // Lesson title same as module for now
             moduleData.youtubeUrlController.text,
             moduleData.descriptionController.text,
             1 // order
           );
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course Published Successfully!')),
      );
      
      Navigator.pop(context); // Go back
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('AI Course Creator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _courseNameController,
                        decoration: const InputDecoration(labelText: 'Course Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _moduleCountController,
                        decoration: const InputDecoration(labelText: 'Number of Modules'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Points Reward',
                          helperText: 'Points awarded for completing this course',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      // Engineering Stream Display (Read-only or Selectable)
                      if (_companyStream != null)
                        TextFormField(
                          initialValue: _companyStream,
                          decoration: const InputDecoration(
                            labelText: 'Engineering Stream',
                            prefixIcon: Icon(Icons.engineering),
                            helperText: 'Based on your company profile',
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateStructure,
                          icon: _isGenerating 
                            ? Container(width: 20, height: 20, child: const CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.auto_awesome),
                          label: Text(_isGenerating ? 'Generating...' : 'Generate Course Structure'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_generatedModules.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Generated Modules', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedModules.length,
                itemBuilder: (context, index) {
                  final module = _generatedModules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Text('${index + 1}. ${module.title}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: module.youtubeUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'YouTube Video URL',
                                  hintText: 'https://youtube.com/...',
                                  prefixIcon: Icon(Icons.video_library),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: module.isGeneratingDesc 
                                        ? null 
                                        : () => _generateDescriptionForModule(index),
                                      icon: const Icon(Icons.psychology),
                                      label: module.isGeneratingDesc 
                                        ? const Text('Thinking...')
                                        : const Text('Generate AI Description'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: module.descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _publishCourse,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('PUBLISH COURSE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

class ModuleData {
  String title;
  final TextEditingController youtubeUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isGeneratingDesc = false;

  ModuleData({required this.title});
}
