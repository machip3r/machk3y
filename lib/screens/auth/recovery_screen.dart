import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _recoveryKeyController = TextEditingController();
  final _newMasterPasswordController = TextEditingController();
  final _confirmMasterPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isNewMasterPasswordVisible = false;
  bool _isConfirmMasterPasswordVisible = false;
  bool _isLoading = false;
  bool _showNewMasterPasswordFields = false;

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _recoveryKeyController.dispose();
    _newMasterPasswordController.dispose();
    _confirmMasterPasswordController.dispose();
    _emailController.removeListener(_onEmailChanged);
    super.dispose();
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

                  // Title
                  Text(
                        'Recover Account',
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
                    'Use your recovery key to reset your master password',
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
                            return 'Please enter your account password';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 700.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),

                  const SizedBox(height: 16),

                  // Recovery Key Input
                  _buildInputField(
                        controller: _recoveryKeyController,
                        label: 'Recovery Key (24 words)',
                        icon: Icons.vpn_key,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your recovery key';
                          }
                          final words = value.trim().split(RegExp(r'\s+'));
                          if (words.length != 24) {
                            return 'Recovery key must be exactly 24 words';
                          }
                          return null;
                        },
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 24),

                  // Verify Button
                  ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
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
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              )
                            : const Text(
                                'Verify Recovery Key',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 900.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 900.ms),

                  // New Master Password Fields (shown after successful verification)
                  if (_showNewMasterPasswordFields) ...[
                    const SizedBox(height: 32),

                    Text(
                      'Set New Master Password',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 8),

                    Text(
                      'Choose a new master password for your vault',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    _buildInputField(
                          controller: _newMasterPasswordController,
                          label: 'New Master Password',
                          icon: Icons.security,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new master password';
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
                          label: 'Confirm New Master Password',
                          icon: Icons.security,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new master password';
                            }
                            if (value != _newMasterPasswordController.text) {
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
                          onPressed: _isLoading ? null : _handleRecovery,
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
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Reset Master Password',
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

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Need Help?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If you don\'t have your recovery key, contact support. We cannot recover your data without it.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

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
    int maxLines = 1,
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
        maxLines: maxLines,
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
    if (controller == _newMasterPasswordController) {
      return _isNewMasterPasswordVisible;
    } else if (controller == _confirmMasterPasswordController) {
      return _isConfirmMasterPasswordVisible;
    } else {
      return _isPasswordVisible;
    }
  }

  void _togglePasswordVisibility(TextEditingController controller) {
    setState(() {
      if (controller == _newMasterPasswordController) {
        _isNewMasterPasswordVisible = !_isNewMasterPasswordVisible;
      } else if (controller == _confirmMasterPasswordController) {
        _isConfirmMasterPasswordVisible = !_isConfirmMasterPasswordVisible;
      } else {
        _isPasswordVisible = !_isPasswordVisible;
      }
    });
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate verification process
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // For demo purposes, always show success
    setState(() {
      _showNewMasterPasswordFields = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery key verified successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.recoverAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      recoveryKey: _recoveryKeyController.text.trim(),
      newMasterPassword: _newMasterPasswordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master password reset successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Recovery failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
}
