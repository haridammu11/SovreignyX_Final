import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/social_service.dart';

class CertificatesScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const CertificatesScreen({super.key, required this.userId, this.token});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> _certificates = [];
  File? _certificateImage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadCertificates();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _certificates = [
          {
            'id': 1,
            'title': 'Python Programming Certificate',
            'issuer': 'Coursera',
            'issueDate': '2025-10-15',
            'expiryDate': '2028-10-15',
            'credentialId': 'PY2025ABC123',
            'color': Colors.blue,
          },
          {
            'id': 2,
            'title': 'Machine Learning Specialization',
            'issuer': 'edX',
            'issueDate': '2025-08-22',
            'expiryDate': '2028-08-22',
            'credentialId': 'ML2025XYZ789',
            'color': Colors.purple,
          },
          {
            'id': 3,
            'title': 'Cloud Computing Fundamentals',
            'issuer': 'Google Cloud',
            'issueDate': '2025-06-30',
            'expiryDate': '2028-06-30',
            'credentialId': 'CC2025GCP456',
            'color': Colors.orange,
          },
        ];
        _isLoading = false;
      });
      _listAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading certificates: $e')),
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

  Future<void> _pickCertificateImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _certificateImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error picking certificate image: $e')),
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

  void _showAddCertificateDialog() {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final credentialIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Certificate',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Certificate Title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: issuerController,
                        decoration: InputDecoration(
                          labelText: 'Issuer',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: credentialIdController,
                        decoration: InputDecoration(
                          labelText: 'Credential ID',
                          prefixIcon: const Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _certificateImage != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _certificateImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                      : Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _pickCertificateImage();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Select Certificate Image'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Certificate would be added in a real implementation',
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Certificate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Certificates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.purple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddCertificateDialog,
            tooltip: 'Add Certificate',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadCertificates,
                  child:
                      _certificates.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade100,
                                        Colors.orange.shade100,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.workspace_premium,
                                    size: 64,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'No certificates yet',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first certificate to showcase your skills',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _showAddCertificateDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text(
                                      'Add Your First Certificate',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              100,
                              16,
                              100,
                            ),
                            itemCount: _certificates.length,
                            itemBuilder: (context, index) {
                              final cert = _certificates[index];
                              final delay = index * 0.1;

                              final slideAnimation = Tween<Offset>(
                                begin: const Offset(0.3, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listAnimationController,
                                  curve: Interval(
                                    delay,
                                    delay + 0.4,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                              final fadeAnimation = Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _listAnimationController,
                                  curve: Interval(
                                    delay,
                                    delay + 0.4,
                                    curve: Curves.easeIn,
                                  ),
                                ),
                              );

                              return SlideTransition(
                                position: slideAnimation,
                                child: FadeTransition(
                                  opacity: fadeAnimation,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          (cert['color'] as Color).withOpacity(
                                            0.05,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (cert['color'] as Color)
                                              .withOpacity(0.2),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      (cert['color'] as Color),
                                                      (cert['color'] as Color)
                                                          .withOpacity(0.7),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: const Icon(
                                                  Icons.workspace_premium,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      cert['title'],
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      cert['issuer'],
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                _buildInfoRow(
                                                  Icons.calendar_today,
                                                  'Issued',
                                                  cert['issueDate'],
                                                  cert['color'] as Color,
                                                ),
                                                const SizedBox(height: 12),
                                                _buildInfoRow(
                                                  Icons.event,
                                                  'Expires',
                                                  cert['expiryDate'],
                                                  cert['color'] as Color,
                                                ),
                                                const SizedBox(height: 12),
                                                _buildInfoRow(
                                                  Icons.confirmation_number,
                                                  'Credential ID',
                                                  cert['credentialId'],
                                                  cert['color'] as Color,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {},
                                                  icon: Icon(
                                                    Icons.share,
                                                    size: 18,
                                                    color:
                                                        cert['color'] as Color,
                                                  ),
                                                  label: const Text('Share'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        cert['color'] as Color,
                                                    side: BorderSide(
                                                      color: (cert['color']
                                                              as Color)
                                                          .withOpacity(0.5),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        cert['color'] as Color,
                                                        (cert['color'] as Color)
                                                            .withOpacity(0.7),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: ElevatedButton.icon(
                                                    onPressed: () {},
                                                    icon: const Icon(
                                                      Icons.visibility,
                                                      size: 18,
                                                    ),
                                                    label: const Text('View'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
      ),
      floatingActionButton:
          _certificates.isNotEmpty
              ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _showAddCertificateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Certificate'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              )
              : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
