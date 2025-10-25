import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _confirmMasterPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isMasterPasswordVisible = false;
  bool _isConfirmMasterPasswordVisible = false;
  bool _isLoading = false;
  bool _showMasterPasswordFields = false;
  bool _hasAcceptedTerms = false;
  String? _recoveryKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Back Button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // App Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 50,
                      color: Color(0xFF6366F1),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .slideY(begin: 0.3, duration: 800.ms, delay: 200.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Set up your secure password vault',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 800.ms, delay: 400.ms),

                  const SizedBox(height: 32),

                  // Email Input
                  _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 16),

                  // Password Input
                  _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 700.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),

                  const SizedBox(height: 16),

                  // Confirm Password Input
                  _buildInputField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 24),

                  // Terms Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAcceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            _hasAcceptedTerms = value ?? false;
                          });
                        },
                        activeColor: Colors.white,
                        checkColor: Theme.of(context).colorScheme.primary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasAcceptedTerms = !_hasAcceptedTerms;
                            });
                          },
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 900.ms),

                  const SizedBox(height: 16),

                  // Register Button
                  ElevatedButton(
                        onPressed: _isLoading || !_hasAcceptedTerms
                            ? null
                            : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1),
                                  ),
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 1000.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 1000.ms),

                  // Master Password Fields (shown after successful registration)
                  if (_showMasterPasswordFields) ...[
                    const SizedBox(height: 32),

                    Text(
                      'Set Master Password',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 8),

                    Text(
                      'This password encrypts your vault. Choose a strong password.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    _buildInputField(
                          controller: _masterPasswordController,
                          label: 'Master Password',
                          icon: Icons.security,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a master password';
                            }
                            if (value.length < 8) {
                              return 'Master password must be at least 8 characters';
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, duration: 400.ms),

                    const SizedBox(height: 16),

                    _buildInputField(
                          controller: _confirmMasterPasswordController,
                          label: 'Confirm Master Password',
                          icon: Icons.security,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your master password';
                            }
                            if (value != _masterPasswordController.text) {
                              return 'Master passwords do not match';
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, duration: 400.ms),

                    const SizedBox(height: 24),

                    ElevatedButton(
                          onPressed: _isLoading ? null : _handleMasterPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6366F1),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Complete Setup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, duration: 400.ms),
                  ],

                  // Recovery Key Display (shown after successful setup)
                  if (_recoveryKey != null) ...[
                    const SizedBox(height: 32),

                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Save Your Recovery Key',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Write down this recovery key and store it safely. You\'ll need it if you forget your master password.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _recoveryKey!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Copy to clipboard
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.2),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Share recovery key
                                      },
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.2),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                value: false,
                                onChanged: (value) {
                                  // Confirm user has saved recovery key
                                },
                                title: Text(
                                  'I have saved my recovery key safely',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                activeColor: Colors.white,
                                checkColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(duration: 600.ms, curve: Curves.elasticOut),
                  ],

                  const SizedBox(height: 24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextButton(
                          onPressed: _goToLogin,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 1100.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_getPasswordVisibility(controller) : false,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _getPasswordVisibility(controller)
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => _togglePasswordVisibility(controller),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  bool _getPasswordVisibility(TextEditingController controller) {
    if (controller == _masterPasswordController ||
        controller == _confirmMasterPasswordController) {
      return controller == _masterPasswordController
          ? _isMasterPasswordVisible
          : _isConfirmMasterPasswordVisible;
    } else if (controller == _confirmPasswordController) {
      return _isConfirmPasswordVisible;
    } else {
      return _isPasswordVisible;
    }
  }

  void _togglePasswordVisibility(TextEditingController controller) {
    setState(() {
      if (controller == _masterPasswordController) {
        _isMasterPasswordVisible = !_isMasterPasswordVisible;
      } else if (controller == _confirmMasterPasswordController) {
        _isConfirmMasterPasswordVisible = !_isConfirmMasterPasswordVisible;
      } else if (controller == _confirmPasswordController) {
        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
      } else {
        _isPasswordVisible = !_isPasswordVisible;
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      masterPassword: '', // Will be set in next step
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _showMasterPasswordFields = true;
        _recoveryKey = result.recoveryKey;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Registration failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Complete the registration with master password
    // This would typically involve updating the user settings
    // For now, we'll just show success and navigate to login

    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! Please sign in.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _masterPasswordController.dispose();
    _confirmMasterPasswordController.dispose();
    super.dispose();
  }
}
