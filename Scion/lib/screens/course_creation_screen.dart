import 'package:flutter/material.dart';
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
  
  bool _isGenerating = false;
  bool _isSaving = false;
  List<ModuleData> _generatedModules = [];
  
  // Service instances
  final _courseService = CourseService();

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
        // Assuming 1 video per module for simplicity as per requirement
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _courseNameController,
                        decoration: const InputDecoration(labelText: 'Course Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _moduleCountController,
                        decoration: const InputDecoration(labelText: 'Number of Modules'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isGenerating ? null : _generateStructure,
                        child: _isGenerating 
                          ? const CircularProgressIndicator() 
                          : const Text('Generate Course Structure'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_generatedModules.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Modules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedModules.length,
                itemBuilder: (context, index) {
                  final module = _generatedModules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text('${index + 1}. ${module.title}'),
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
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: module.isGeneratingDesc 
                                        ? null 
                                        : () => _generateDescriptionForModule(index),
                                      icon: const Icon(Icons.auto_awesome),
                                      label: module.isGeneratingDesc 
                                        ? const Text('Generating...')
                                        : const Text('Generate AI Description'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: module.descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
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
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _publishCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('PUBLISH COURSE', style: TextStyle(fontSize: 18, color: Colors.white)),
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
