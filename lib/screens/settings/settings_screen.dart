import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isEnabled = await authProvider.isBiometricUnlockEnabled();
    setState(() {
      _isBiometricEnabled = isEnabled;
    });
  }

  Future<bool> _checkBiometricAvailability() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAvailable = await authProvider.checkBiometricAvailability();
      return isAvailable;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // First check if biometrics are available on the device
    final isAvailable = await _checkBiometricAvailability();
    if (!isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication is not set up on your device. Please enable Touch ID or Face ID in your phone settings.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      // Reset toggle to previous state
      setState(() {
        _isBiometricEnabled = !value;
      });
      return;
    }

    if (value) {
      // Enabling biometrics - require master password
      await _showMasterPasswordDialog(authProvider, true);
    } else {
      // Disabling biometrics - require biometric verification
      await _verifyBiometricAndDisable(authProvider);
    }
  }

  Future<void> _showMasterPasswordDialog(
    AuthProvider authProvider,
    bool enableBiometric,
  ) async {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Biometric Unlock'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your master password to enable biometric unlock',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      if (passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your master password'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop(passwordController.text);
                    },
                    child: const Text('Enable'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // Handle the returned password
    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      final enableResult = await authProvider.enableBiometricUnlock(result);

      setState(() {
        _isLoading = false;
      });

      if (enableResult.success) {
        setState(() {
          _isBiometricEnabled = true;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric unlock enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          final errorMessage =
              enableResult.error ?? 'Failed to enable biometric unlock';
          final friendlyMessage =
              errorMessage.toLowerCase().contains('not set up') ||
                  errorMessage.toLowerCase().contains('not available')
              ? 'Biometric authentication is not set up. Please enable Touch ID or Face ID in your device settings.'
              : errorMessage;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }

    // Dispose controller
    passwordController.dispose();
  }

  Future<void> _verifyBiometricAndDisable(AuthProvider authProvider) async {
    setState(() {
      _isLoading = true;
    });

    final result = await authProvider.unlockVaultWithBiometrics();

    if (result.success) {
      // Biometric verified, now disable it
      final disableResult = await authProvider.disableBiometricUnlock();
      setState(() {
        _isLoading = false;
        _isBiometricEnabled = false;
      });

      if (context.mounted) {
        if (disableResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric unlock disabled'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                disableResult.error ?? 'Failed to disable biometric unlock',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Biometric verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            'Email',
            Provider.of<AuthProvider>(context).currentUser?.email ?? '',
            Icons.email_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'Change Master Password',
            'Update your master password',
            Icons.lock_outline,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'View Recovery Key',
            'Show your recovery key',
            Icons.vpn_key,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader(context, 'Security'),
          _buildSettingsTile(
            context,
            'Biometric Unlock',
            'Use fingerprint or face unlock',
            Icons.fingerprint,
            trailing: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: _isBiometricEnabled,
                    onChanged: _handleBiometricToggle,
                  ),
            onTap: null,
          ),
          _buildSettingsTile(
            context,
            'Auto-lock',
            'Lock vault after inactivity',
            Icons.timer_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'Clipboard Timeout',
            'Clear clipboard after copying',
            Icons.content_copy,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsTile(
            context,
            'Theme',
            'Light, Dark, or System',
            Icons.palette_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'Accent Color',
            'Choose your favorite color',
            Icons.color_lens_outlined,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          _buildSettingsTile(
            context,
            'Export Data',
            'Download your credentials',
            Icons.download_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'Import Data',
            'Import from another app',
            Icons.upload_outlined,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            'Backup',
            'Create encrypted backup',
            Icons.backup_outlined,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone'),
          _buildSettingsTile(
            context,
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_forever,
            textColor: Colors.red,
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              textColor ??
              (isDark
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement account deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
