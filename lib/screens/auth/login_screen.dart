import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/config/env.dart';
import '../../core/services/storage_service.dart';
import 'register_screen.dart';
import 'recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _masterPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isMasterPasswordVisible = false;
  bool _isLoading = false;
  bool _showMasterPasswordField = false;

  // Email suggestions
  bool _showEmailSuggestions = false;
  List<String> _emailSuggestions = [];
  final List<String> _commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'yahoo.com.mx',
    'hotmail.com.mx',
    'live.com',
    'icloud.com',
    'aol.com',
    'protonmail.com',
    'yandex.com',
    'mail.com',
    'zoho.com',
    'fastmail.com',
    'tutanota.com',
  ];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    final atIndex = text.lastIndexOf('@');

    if (atIndex != -1) {
      final domainPart = text.substring(atIndex + 1);
      if (domainPart.isNotEmpty) {
        _emailSuggestions = _commonDomains
            .where(
              (domain) =>
                  domain.toLowerCase().startsWith(domainPart.toLowerCase()),
            )
            .toList();
        setState(() {
          _showEmailSuggestions = _emailSuggestions.isNotEmpty;
        });
      } else {
        setState(() {
          _showEmailSuggestions = true;
          _emailSuggestions = _commonDomains;
        });
      }
    } else {
      setState(() {
        _showEmailSuggestions = false;
      });
    }
  }

  void _selectEmailSuggestion(String domain) {
    final text = _emailController.text;
    final atIndex = text.lastIndexOf('@');

    if (atIndex != -1) {
      final username = text.substring(0, atIndex);
      _emailController.text = '$username@$domain';
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }

    setState(() {
      _showEmailSuggestions = false;
    });
  }

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
                  const SizedBox(height: 40),

                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: Color(0xFF6366F1),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 32),

                  // Welcome Text
                  Text(
                        'Welcome Back!',
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
                    'Sign in to access your secure vault',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 800.ms, delay: 400.ms),

                  const SizedBox(height: 48),

                  // Email Input with Suggestions
                  _buildEmailInputWithSuggestions()
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
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 700.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),

                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 16),

                  // Master Password Field (shown after successful auth)
                  if (_showMasterPasswordField) ...[
                    _buildInputField(
                          controller: _masterPasswordController,
                          label: 'Master Password',
                          icon: Icons.security,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your master password';
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.3, duration: 400.ms),

                    const SizedBox(height: 16),

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
                                  'Unlock Vault',
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

                  const SizedBox(height: 24),

                  // Forgot Password
                  TextButton(
                    onPressed: _goToRecovery,
                    child: Text(
                      'Forgot your master password?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 900.ms),

                  const SizedBox(height: 16),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextButton(
                          onPressed: _goToRegister,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 40),

                  // Debug: Reset Onboarding Button (remove in production)
                  if (Env.isDebug)
                    TextButton(
                      onPressed: () async {
                        final storageService = Provider.of<StorageService>(
                          context,
                          listen: false,
                        );
                        await storageService.resetOnboarding();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Onboarding reset! Restart the app to see onboarding again.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        'Reset Onboarding (Debug)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInputWithSuggestions() {
    return Column(
      children: [
        Container(
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_showEmailSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _emailSuggestions.take(5).map((domain) {
                final text = _emailController.text;
                final atIndex = text.lastIndexOf('@');
                final username = atIndex != -1
                    ? text.substring(0, atIndex)
                    : '';
                final fullEmail = '$username@$domain';

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.email, size: 16),
                  title: Text(fullEmail, style: const TextStyle(fontSize: 14)),
                  onTap: () => _selectEmailSuggestion(domain),
                );
              }).toList(),
            ),
          ),
        ],
      ],
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
        obscureText: isPassword ? !_getPasswordVisibility(isPassword) : false,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _getPasswordVisibility(isPassword)
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => _togglePasswordVisibility(isPassword),
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

  bool _getPasswordVisibility(bool isMasterPassword) {
    return isMasterPassword ? _isMasterPasswordVisible : _isPasswordVisible;
  }

  void _togglePasswordVisibility(bool isMasterPassword) {
    setState(() {
      if (isMasterPassword) {
        _isMasterPasswordVisible = !_isMasterPasswordVisible;
      } else {
        _isPasswordVisible = !_isPasswordVisible;
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_showMasterPasswordField) {
      // First step: Initial login (email + password)
      final result = await authProvider.initialLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _showMasterPasswordField = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Login failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      // Second step: Complete login with master password
      final result = await authProvider.completeLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        masterPassword: _masterPasswordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Navigate to dashboard or main app
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Login failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.completeLogin(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      masterPassword: _masterPasswordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      // Navigate to dashboard or main app
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Master password incorrect'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
  }

  void _goToRecovery() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RecoveryScreen()));
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _masterPasswordController.dispose();
    super.dispose();
  }
}
