import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';

class MasterPasswordSetupScreen extends StatefulWidget {
  final String recoveryKey;

  const MasterPasswordSetupScreen({super.key, required this.recoveryKey});

  @override
  State<MasterPasswordSetupScreen> createState() =>
      _MasterPasswordSetupScreenState();
}

class _MasterPasswordSetupScreenState extends State<MasterPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masterPasswordController = TextEditingController();
  final _confirmMasterPasswordController = TextEditingController();

  bool _isMasterPasswordVisible = false;
  bool _isConfirmMasterPasswordVisible = false;
  bool _isLoading = false;
  bool _hasSavedRecoveryKey = false;

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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate().scale(duration: 600.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // Success Message
                  Text(
                    'Account Created!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Now let\'s secure your vault with a master password',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 48),

                  // Master Password Input
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
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 16),

                  // Confirm Master Password Input
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
                      .fadeIn(duration: 600.ms, delay: 900.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 900.ms),

                  const SizedBox(height: 32),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your master password encrypts your vault. Choose a strong, memorable password.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 24),

                  // Recovery Key Display
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
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Save Your Recovery Key',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Write down this recovery key and store it safely. You\'ll need it if you forget your master password.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
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
                            widget.recoveryKey,
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
                                onPressed: _copyRecoveryKey,
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareRecoveryKey,
                                icon: const Icon(Icons.share, size: 16),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _hasSavedRecoveryKey,
                          onChanged: (value) {
                            setState(() {
                              _hasSavedRecoveryKey = value ?? false;
                            });
                          },
                          title: Text(
                            'I have saved my recovery key safely',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                          activeColor: Colors.white,
                          checkColor: Theme.of(context).colorScheme.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),

                  const SizedBox(height: 32),

                  // Complete Setup Button
                  SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || !_hasSavedRecoveryKey
                              ? null
                              : _handleCompleteSetup,
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
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 1300.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 1300.ms),

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
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _getPasswordVisibility(controller)
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => _togglePasswordVisibility(controller),
                )
              : null,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  bool _getPasswordVisibility(TextEditingController controller) {
    if (controller == _masterPasswordController) {
      return _isMasterPasswordVisible;
    } else if (controller == _confirmMasterPasswordController) {
      return _isConfirmMasterPasswordVisible;
    }
    return false;
  }

  void _togglePasswordVisibility(TextEditingController controller) {
    setState(() {
      if (controller == _masterPasswordController) {
        _isMasterPasswordVisible = !_isMasterPasswordVisible;
      } else if (controller == _confirmMasterPasswordController) {
        _isConfirmMasterPasswordVisible = !_isConfirmMasterPasswordVisible;
      }
    });
  }

  void _copyRecoveryKey() {
    Clipboard.setData(ClipboardData(text: widget.recoveryKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery key copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareRecoveryKey() {
    Share.share(
      'My MachK3y Recovery Key:\n\n${widget.recoveryKey}\n\nSave this key safely - you\'ll need it to recover your vault if you forget your master password.',
      subject: 'MachK3y Recovery Key',
    );
  }

  Future<void> _handleCompleteSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Complete the registration with master password
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.completeRegistration(
        masterPassword: _masterPasswordController.text,
        recoveryKey: widget.recoveryKey,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to main app - AppWrapper will handle routing
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Setup failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _masterPasswordController.dispose();
    _confirmMasterPasswordController.dispose();
    super.dispose();
  }
}
