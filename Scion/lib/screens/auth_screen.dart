import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _googleSignInAvailable = true;
  bool _isWebPlatform = false;
  late AnimationController _formAnimationController;
  late AnimationController _logoAnimationController;

  late final GoogleSignIn _googleSignInInstance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _formAnimationController.forward();
    _logoAnimationController.forward();

    _isWebPlatform = identical(0, 0.0);

    try {
      if (_isWebPlatform) {
        _googleSignInAvailable = false;
        print(
          'Google Sign-In disabled on web platform per Android client ID preference',
        );
      } else {
        _googleSignInInstance = GoogleSignIn(scopes: ['email', 'profile']);
      }
    } catch (e) {
      _googleSignInAvailable = false;
      print('Google Sign-In not available: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          final result = await _authService.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          if (result['success']) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/dashboard',
                arguments: {'authService': _authService},
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(result['error'].toString())),
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
        } else {
          final result = await _authService.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );

          if (result['success']) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/interests-selection',
                arguments: {'authService': _authService},
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(result['error'].toString())),
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _performGoogleSignIn() async {
    if (!_googleSignInAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Google Sign-In is not available on this platform'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    if (_isWebPlatform) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Google Sign-In not supported on web with Android client ID preference',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _googleSignInInstance.signOut();
      final GoogleSignInAccount? googleUser =
          await _googleSignInInstance.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final String email = googleUser.email;
        final String displayName = googleUser.displayName ?? '';
        final String photoUrl = googleUser.photoUrl ?? '';
        final String idToken = googleAuth.idToken ?? '';

        String firstName = '';
        String lastName = '';

        if (displayName.isNotEmpty) {
          final nameParts = displayName.split(' ');
          if (nameParts.length >= 2) {
            firstName = nameParts[0];
            lastName = nameParts.sublist(1).join(' ');
          } else {
            firstName = displayName;
            lastName = displayName;
          }
        }

        if (firstName.isEmpty || lastName.isEmpty) {
          if (email.isNotEmpty) {
            final emailParts = email.split('@');
            final emailPrefix = emailParts[0];
            if (firstName.isEmpty) firstName = emailPrefix;
            if (lastName.isEmpty) lastName = emailPrefix;
          }
        }

        if (firstName.isEmpty) firstName = 'User';
        if (lastName.isEmpty) lastName = 'Google';

        if (email.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Email is required but not provided by Google'),
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
          return;
        }

        if (idToken.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('ID Token is required but not provided by Google'),
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
          return;
        }

        print('Sending to backend:');
        print('  Email: $email');
        print('  First Name: $firstName');
        print('  Last Name: $lastName');
        print('  ID Token: $idToken');
        print('  Photo URL: $photoUrl');

        final result = await _authService.googleSignIn(
          idToken: idToken,
          email: email,
          firstName: firstName,
          lastName: lastName,
          photoUrl: photoUrl.isEmpty ? null : photoUrl,
        );

        if (result['success']) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: {'authService': _authService},
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign-In failed: ${result['error'].toString()}',
                      ),
                    ),
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Google Sign-In canceled'),
                ],
              ),
              backgroundColor: Colors.grey.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Google Sign-In requires Android setup. Check console for details.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        print('Google Sign-In Android setup required: $e');
        print('To fix this issue:');
        print('1. Add google-services.json to android/app/ directory');
        print(
          '2. Configure SHA-1 fingerprint in Firebase/Google Cloud Console',
        );
        print(
          '3. Make sure you have the correct package name in your configuration',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Google Sign-In failed: ${e.toString()}')),
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

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _formAnimationController.reset();
    _formAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          // Removed gradient to stick to Scion Dark Theme
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _formAnimationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _formAnimationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outline.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo and Title
                            ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.8,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: _logoAnimationController,
                                  curve: Curves.elasticOut,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cs.primary.withOpacity(0.5)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 48,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _isLogin ? 'Welcome Back!' : 'Create Account',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? 'Sign in to continue learning'
                                  : 'Join our learning community',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Form Fields
                            if (!_isLogin) ...[
                              _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _usernameController,
                                label: 'Username',
                                icon: Icons.alternate_email,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: cs.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          _isLogin
                                              ? 'Sign In'
                                              : 'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimary,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // Google Sign In
                            if (_googleSignInAvailable && !_isWebPlatform) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: cs.outlineVariant),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: cs.outlineVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _performGoogleSignIn,
                                  icon: Icon(
                                    Icons.g_mobiledata,
                                    size: 32,
                                    color: cs.primary,
                                  ),
                                  label: Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: cs.outline,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Toggle Auth Mode
                            TextButton(
                              onPressed: _isLoading ? null : _toggleAuthMode,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isLogin
                                          ? "Don't have an account? "
                                          : 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: _isLogin ? 'Sign Up' : 'Sign In',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: cs.onSurface), // Ensure text is visible
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(icon, color: cs.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: cs.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest, // Dark background
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.7)),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
