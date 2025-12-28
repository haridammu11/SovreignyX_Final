import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const SecuritySettingsScreen({super.key, required this.userId, this.token});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _twoFactorEnabled = false;
  String _selectedAuthMethod = 'email';
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = false;
  String _password = '';
  String _newPassword = '';
  String _confirmPassword = '';

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateSecuritySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would make API calls to update security settings
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security settings updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update security settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would make an API call to change the password
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _passwordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to change password: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _enableTwoFactorAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would make an API call to enable 2FA
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _twoFactorEnabled = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication enabled')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to enable two-factor authentication: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _disableTwoFactorAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, you would make an API call to disable 2FA
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _twoFactorEnabled = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication disabled')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to disable two-factor authentication: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
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
                      // Change password section
                      const Text(
                        'Change Password',
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
                              TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Password',
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _newPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm New Password',
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _changePassword,
                                  child:
                                      _isLoading
                                          ? const Text('Changing...')
                                          : const Text('Change Password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Two-factor authentication
                      const Text(
                        'Two-Factor Authentication',
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
                                'Add an extra layer of security to your account',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text(
                                  'Enable Two-Factor Authentication',
                                ),
                                value: _twoFactorEnabled,
                                onChanged: (value) {
                                  if (value) {
                                    _enableTwoFactorAuth();
                                  } else {
                                    _disableTwoFactorAuth();
                                  }
                                },
                              ),
                              if (_twoFactorEnabled) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Authentication Method',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  title: const Text('Authenticator App'),
                                  leading: Radio<String>(
                                    value: 'authenticator',
                                    groupValue: _selectedAuthMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAuthMethod = value!;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedAuthMethod = 'authenticator';
                                    });
                                  },
                                ),
                                ListTile(
                                  title: const Text('SMS'),
                                  leading: Radio<String>(
                                    value: 'sms',
                                    groupValue: _selectedAuthMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAuthMethod = value!;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedAuthMethod = 'sms';
                                    });
                                  },
                                ),
                                ListTile(
                                  title: const Text('Email'),
                                  leading: Radio<String>(
                                    value: 'email',
                                    groupValue: _selectedAuthMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAuthMethod = value!;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedAuthMethod = 'email';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Security notifications
                      const Text(
                        'Security Notifications',
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
                                title: const Text('Send security alerts'),
                                subtitle: const Text(
                                  'Get notified of suspicious activities',
                                ),
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                              ),
                              const Divider(),
                              SwitchListTile(
                                title: const Text('Location tracking'),
                                subtitle: const Text(
                                  'Track login locations for security',
                                ),
                                value: _locationTrackingEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _locationTrackingEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Connected devices
                      const Text(
                        'Connected Devices',
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
                              _DeviceItem(
                                device: 'Windows PC',
                                location: 'New York, USA',
                                lastActive: '2 hours ago',
                                isCurrent: true,
                              ),
                              const Divider(),
                              _DeviceItem(
                                device: 'iPhone 12',
                                location: 'San Francisco, USA',
                                lastActive: '1 day ago',
                                isCurrent: false,
                              ),
                              const Divider(),
                              _DeviceItem(
                                device: 'MacBook Pro',
                                location: 'London, UK',
                                lastActive: '3 days ago',
                                isCurrent: false,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Sign out of all devices
                                  },
                                  child: const Text('Sign Out of All Devices'),
                                ),
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
                          onPressed:
                              _isLoading ? null : _updateSecuritySettings,
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

class _DeviceItem extends StatelessWidget {
  final String device;
  final String location;
  final String lastActive;
  final bool isCurrent;

  const _DeviceItem({
    required this.device,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isCurrent ? Icons.laptop : Icons.phone_iphone,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(location),
              Text(
                lastActive,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (isCurrent)
          const Chip(label: Text('Current'), backgroundColor: Colors.green)
        else
          TextButton(
            onPressed: () {
              // Sign out this device
            },
            child: const Text('Sign Out'),
          ),
      ],
    );
  }
}
