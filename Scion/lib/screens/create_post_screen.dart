import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/social_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String? token;

  const CreatePostScreen({super.key, required this.userId, this.token});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _selectedContentType = 'text';
  String? _postTitle;

  File? _postImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickPostImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _postImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error picking image: $e')),
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

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? imageUrl;
        final client = Supabase.instance.client;

        // 1. Upload Image if present
        if (_postImage != null) {
          final bytes = await _postImage!.readAsBytes();
          final fileExt = _postImage!.path.split('.').last;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${widget.userId}.$fileExt';
          final filePath = fileName;

          try {
            // Try 'post_images' bucket first (Root level)
            await client.storage
                .from('post_images')
                .uploadBinary(
                  filePath,
                  bytes,
                  fileOptions: FileOptions(
                    contentType: 'image/$fileExt',
                    upsert: true,
                  ),
                );
            imageUrl = client.storage
                .from('post_images')
                .getPublicUrl(filePath);
          } catch (e) {
            print(
              'Bucket post_images not found ($e). Trying publics/post_images...',
            );
            try {
              // Fallback: Try 'publics' bucket with subfolder
              final folderPath = 'post_images/$fileName';
              await client.storage
                  .from('publics')
                  .uploadBinary(
                    folderPath,
                    bytes,
                    fileOptions: FileOptions(
                      contentType: 'image/$fileExt',
                      upsert: true,
                    ),
                  );
              imageUrl = client.storage
                  .from('publics')
                  .getPublicUrl(folderPath);
            } catch (e2) {
              print('Backups failed. Image upload aborted: $e2');
            }
          }
        }

        // 2. Prepare Content
        String finalContent = _contentController.text;
        if (_selectedContentType != 'text') {
          String displayTitle = _postTitle ?? 'Untitled';
          finalContent =
              '[${_selectedContentType!.toUpperCase()}] $displayTitle\n\n$finalContent';
        }

        // 3. Create Post
        final socialService = SocialService(token: widget.token);
        await socialService.createPost(
          authorId: widget.userId,
          content: finalContent,
          image: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Post created successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error creating post: $e')),
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade700, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content type selector
                const Text(
                  'Content Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedContentType,
                    items: const [
                      DropdownMenuItem(
                        value: 'text',
                        child: Row(
                          children: [
                            Icon(Icons.text_fields, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Text Post'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'certificate',
                        child: Row(
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.amber),
                            SizedBox(width: 12),
                            Text('Certificate'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'resume',
                        child: Row(
                          children: [
                            Icon(Icons.description, color: Colors.green),
                            SizedBox(width: 12),
                            Text('Resume'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'project',
                        child: Row(
                          children: [
                            Icon(Icons.code, color: Colors.purple),
                            SizedBox(width: 12),
                            Text('Project'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedContentType = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title field (for certificates, resumes, projects)
                if (_selectedContentType != 'text')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter a title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.purple.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (_selectedContentType != 'text' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _postTitle = value;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Content field
                const Text(
                  'Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _getContentLabel(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.purple.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.purple.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.purple.shade700,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter content';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Image preview
                if (_postImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Image Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _postImage = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_postImage!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Upload button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _pickPostImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _selectedContentType != 'text'
                          ? Icons.upload_file
                          : Icons.image,
                      color: Colors.white,
                    ),
                    label: Text(
                      _selectedContentType != 'text'
                          ? 'Upload File'
                          : 'Add Image',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Create Post',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

  String _getContentLabel() {
    switch (_selectedContentType) {
      case 'certificate':
        return 'Describe your certificate...';
      case 'resume':
        return 'Share your resume highlights...';
      case 'project':
        return 'Describe your project...';
      default:
        return 'What\'s on your mind?';
    }
  }
}
