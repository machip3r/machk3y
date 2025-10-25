import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            trailing: Switch(value: false, onChanged: (value) {}),
            onTap: () {},
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? Theme.of(context).colorScheme.primary,
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
