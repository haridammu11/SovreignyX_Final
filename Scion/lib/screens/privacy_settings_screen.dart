import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const PrivacySettingsScreen({super.key, required this.userId, this.token});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  // Privacy settings
  bool _profilePublic = true;
  bool _showEmail = false;
  bool _showEnrollments = true;
  bool _allowMessaging = true;
  bool _allowFollowing = true;
  bool _shareProgress = false;
  String _dataRetentionPeriod = '1_year';
  bool _analyticsCollection = true;
  bool _personalizedAds = false;

  Future<void> _updatePrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would make API calls to update privacy settings
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update privacy settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestDataExport() async {
    try {
      // In a real implementation, you would make an API call to request data export
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data export request submitted. You will receive an email shortly.',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request data export: $e';
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone. '
            'All your data will be permanently removed from our systems.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // In a real implementation, you would make an API call to delete the account
        await Future.delayed(const Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deletion request submitted')),
        );

        // Navigate to login screen
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to delete account: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                        });
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile visibility
                      const Text(
                        'Profile Visibility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Make profile public'),
                                subtitle: const Text(
                                  'Allow anyone to view your profile',
                                ),
                                value: _profilePublic,
                                onChanged: (value) {
                                  setState(() {
                                    _profilePublic = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text('Show email address'),
                                subtitle: const Text(
                                  'Display your email on your profile',
                                ),
                                value: _showEmail,
                                onChanged: (value) {
                                  setState(() {
                                    _showEmail = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text('Show course enrollments'),
                                subtitle: const Text(
                                  'Display courses you\'re enrolled in',
                                ),
                                value: _showEnrollments,
                                onChanged: (value) {
                                  setState(() {
                                    _showEnrollments = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Communication preferences
                      const Text(
                        'Communication Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Allow direct messaging'),
                                subtitle: const Text(
                                  'Other users can send you messages',
                                ),
                                value: _allowMessaging,
                                onChanged: (value) {
                                  setState(() {
                                    _allowMessaging = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text('Allow following'),
                                subtitle: const Text(
                                  'Other users can follow you',
                                ),
                                value: _allowFollowing,
                                onChanged: (value) {
                                  setState(() {
                                    _allowFollowing = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text('Share learning progress'),
                                subtitle: const Text(
                                  'Show your progress to followers',
                                ),
                                value: _shareProgress,
                                onChanged: (value) {
                                  setState(() {
                                    _shareProgress = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Data retention
                      const Text(
                        'Data Retention',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How long we keep your data',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('1 year (default)'),
                                leading: Radio<String>(
                                  value: '1_year',
                                  groupValue: _dataRetentionPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _dataRetentionPeriod = value!;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _dataRetentionPeriod = '1_year';
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text('3 years'),
                                leading: Radio<String>(
                                  value: '3_years',
                                  groupValue: _dataRetentionPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _dataRetentionPeriod = value!;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _dataRetentionPeriod = '3_years';
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text('5 years'),
                                leading: Radio<String>(
                                  value: '5_years',
                                  groupValue: _dataRetentionPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _dataRetentionPeriod = value!;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _dataRetentionPeriod = '5_years';
                                  });
                                },
                              ),
                              ListTile(
                                title: const Text('Indefinitely'),
                                leading: Radio<String>(
                                  value: 'indefinitely',
                                  groupValue: _dataRetentionPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _dataRetentionPeriod = value!;
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _dataRetentionPeriod = 'indefinitely';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Analytics and personalization
                      const Text(
                        'Analytics and Personalization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Collect usage analytics'),
                                subtitle: const Text(
                                  'Help us improve by sharing usage data',
                                ),
                                value: _analyticsCollection,
                                onChanged: (value) {
                                  setState(() {
                                    _analyticsCollection = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text(
                                  'Personalized advertisements',
                                ),
                                subtitle: const Text(
                                  'Show ads based on your interests',
                                ),
                                value: _personalizedAds,
                                onChanged: (value) {
                                  setState(() {
                                    _personalizedAds = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Data management
                      const Text(
                        'Data Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text('Export your data'),
                                subtitle: const Text(
                                  'Request a copy of your personal data',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: _requestDataExport,
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('Delete your account'),
                                subtitle: const Text(
                                  'Permanently remove your account and data',
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: _deleteAccount,
                                textColor: Colors.red,
                                iconColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePrivacySettings,
                          child:
                              _isLoading
                                  ? const Text('Saving...')
                                  : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
