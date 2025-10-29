import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'code_confirmation_screen.dart';

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

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _hasAcceptedTerms = false;

  // Email suggestions
  bool _showEmailSuggestions = false;
  List<String> _emailSuggestions = [];
  final List<String> _commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'yahoo.com.mx',
    'live.com',
    'live.com.mx',
    'icloud.com',
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
      backgroundColor: Colors.transparent,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Container(
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
            child: Center(
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

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
                              if (value == true) {
                                _showTermsAndPrivacyDialog();
                              } else {
                                setState(() {
                                  _hasAcceptedTerms = false;
                                });
                              }
                            },
                            activeColor: Colors.white,
                            checkColor: Theme.of(context).colorScheme.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_hasAcceptedTerms) {
                                  _showTermsAndPrivacyDialog();
                                } else {
                                  setState(() {
                                    _hasAcceptedTerms = false;
                                  });
                                }
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
                              disabledBackgroundColor: Colors.white.withValues(
                                alpha: 0.5,
                              ),
                              disabledForegroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.5),
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
                                        AppTheme.primaryColor,
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
                              onPressed: () => Navigator.of(context).pop(),
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
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-z0-9@.]')),
            ],
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
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
                  leading: Icon(
                    Icons.email,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  title: Text(
                    fullEmail,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Zalando',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
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
    if (controller == _confirmPasswordController) {
      return _isConfirmPasswordVisible;
    } else {
      return _isPasswordVisible;
    }
  }

  void _togglePasswordVisibility(TextEditingController controller) {
    setState(() {
      if (controller == _confirmPasswordController) {
        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
      } else {
        _isPasswordVisible = !_isPasswordVisible;
      }
    });
  }

  Future<void> _showTermsAndPrivacyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Terms of Service and Privacy Policy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lexend',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome to our platform. By using our services, you agree to comply with all applicable laws and regulations. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n'
                  'We reserve the right to suspend or terminate your account if you violate these terms or engage in any illegal activities. We are not liable for any damages resulting from the use or inability to use our services.',
                  style: TextStyle(fontSize: 14, fontFamily: 'Zalando'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We are committed to protecting your privacy and personal information. We collect and process your data only for the purposes of providing our services.\n\n'
                  'Your account information, including email addresses and encrypted data, is stored securely. We use industry-standard encryption to protect your sensitive information. We do not share your personal data with third parties without your explicit consent.\n\n'
                  'You have the right to access, modify, or delete your personal information at any time through your account settings.',
                  style: TextStyle(fontSize: 14, fontFamily: 'Zalando'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By continuing, you acknowledge that you have read, understood, and agree to be bound by these terms and our privacy policy.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Zalando',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Decline',
                style: TextStyle(fontFamily: 'Zalando', color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasAcceptedTerms = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Accept',
                style: TextStyle(fontFamily: 'Zalando'),
              ),
            ),
          ],
        );
      },
    );
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
    );

    if (!mounted) return;

    if (result.success) {
      // Navigate to code confirmation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CodeConfirmationScreen(
            email: _emailController.text.trim(),
            recoveryKey: result.recoveryKey ?? '',
          ),
        ),
      );
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

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
