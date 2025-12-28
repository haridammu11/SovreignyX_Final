import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add Provider import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart'; // Import ThemeProvider
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  String? _selectedStream;
  bool _isLoading = false;
  bool _isLogin = true;

  final List<String> _engineeringStreams = [
    'Computer Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Electronics Engineering',
    'Chemical Engineering',
    'Aerospace Engineering',
    'Biomedical Engineering',
    'Environmental Engineering',
    'Industrial Engineering',
  ];

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Validate registration fields
        final companyName = _companyNameController.text.trim();
        if (companyName.isEmpty) {
          throw 'Please enter company name';
        }
        if (_selectedStream == null) {
          throw 'Please select engineering stream';
        }

        // Sign up user
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        
        if (response.session == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Please check your email.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Create company profile
        await Supabase.instance.client.from('companies').insert({
          'email': email,
          'name': companyName,
          'engineering_stream': _selectedStream,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
              ),
            ),
          ),
          
          // Pattern Overlay (Optional - simplified for now)
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Branding
                  Icon(
                    Icons.business_center_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Company Portal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enterprise Recruitment & Management',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    width: 400, // Max width for desktop/tablet
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLogin ? 'Welcome Back' : 'Create Account',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              
                              // Company Name (only for registration)
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _companyNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Company Name',
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              // Engineering Stream (only for registration)
                              if (!_isLogin) ...[
                                DropdownButtonFormField<String>(
                                  value: _selectedStream,
                                  decoration: const InputDecoration(
                                    labelText: 'Engineering Stream',
                                    prefixIcon: Icon(Icons.engineering),
                                  ),
                                  items: _engineeringStreams.map((stream) {
                                    return DropdownMenuItem(
                                      value: stream,
                                      child: Text(stream),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedStream = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                ),
                              ),
                              const SizedBox(height: 32),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shadowColor: colorScheme.primary.withOpacity(0.4),
                                  elevation: 8,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_isLogin ? 'Sign In' : 'Register'),
                              ),
                              
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => setState(() => _isLogin = !_isLogin),
                                child: Text(_isLogin
                                    ? 'Don\'t have an account? Create one'
                                    : 'Already have an account? Sign in'),
                              ),
                              
                              const Divider(height: 32),
                              
                              OutlinedButton.icon(
                                onPressed: () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await Supabase.instance.client.auth.signInAnonymously();
                                    if (mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                      );
                                    }
                                  } catch (e) {
                                     if(mounted) setState(() => _isLoading = false);
                                  }
                                },
                                icon: const Icon(Icons.code),
                                label: const Text('Developer Guest Mode'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              // Theme Toggle for Login Screen convenience
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.light_mode, size: 16),
                                  Switch(
                                    value: Provider.of<ThemeProvider>(context).isDarkMode,
                                    onChanged: (val) =>
                                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val),
                                  ),
                                  const Icon(Icons.dark_mode, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
