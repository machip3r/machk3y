import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/credential.dart';
import '../vault/vault_screen.dart';
import '../generator/password_generator_screen.dart';
import '../audit/security_audit_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/security_score.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const VaultScreen(),
    const PasswordGeneratorScreen(),
    const SecurityAuditScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_outlined),
            activeIcon: Icon(Icons.vpn_key),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined),
            activeIcon: Icon(Icons.security),
            label: 'Audit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to add credential
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MachK3y'),
        actions: [
          IconButton(
            onPressed: () {
              // Show notifications
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {
              // Show profile menu
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Consumer<VaultProvider>(
        builder: (context, vaultProvider, child) {
          if (vaultProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => vaultProvider.refreshCredentials(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context, vaultProvider),

                  const SizedBox(height: 24),

                  // Security Score
                  SecurityScoreWidget(
                        securityScore:
                            vaultProvider.securityStats.securityScore,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.3, duration: 600.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsSection(context, vaultProvider),

                  const SizedBox(height: 24),

                  // Password Strength Chart
                  _buildPasswordStrengthChart(context, vaultProvider),

                  const SizedBox(height: 24),

                  // Recent Activity
                  _buildRecentActivity(context, vaultProvider),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    VaultProvider vaultProvider,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final userName = user?.email?.split('@').first ?? 'User';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Welcome back, $userName!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.3, duration: 600.ms),

          const SizedBox(height: 8),

          Text(
                'Your vault is secure and ready to use',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideX(begin: -0.3, duration: 600.ms, delay: 200.ms),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vault unlocked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, VaultProvider vaultProvider) {
    final stats = vaultProvider.securityStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Overview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child:
                  StatCard(
                        title: 'Total Credentials',
                        value: stats.totalCredentials.toString(),
                        icon: Icons.folder_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 400.ms),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  StatCard(
                        title: 'Strong Passwords',
                        value: stats.strongPasswords.toString(),
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        badge: stats.strongPasswords > 0
                            ? '${((stats.strongPasswords / stats.totalCredentials) * 100).toInt()}%'
                            : null,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 500.ms),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child:
                  StatCard(
                        title: 'Weak Passwords',
                        value: stats.weakPasswords.toString(),
                        icon: Icons.warning_outlined,
                        color: Colors.orange,
                        badge: stats.weakPasswords > 0
                            ? '${((stats.weakPasswords / stats.totalCredentials) * 100).toInt()}%'
                            : null,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 600.ms),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  StatCard(
                        title: 'Compromised',
                        value: stats.compromisedPasswords.toString(),
                        icon: Icons.error_outline,
                        color: Colors.red,
                        badge: stats.compromisedPasswords > 0 ? 'Alert!' : null,
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 700.ms)
                      .slideX(begin: -0.3, duration: 600.ms, delay: 700.ms),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthChart(
    BuildContext context,
    VaultProvider vaultProvider,
  ) {
    final stats = vaultProvider.securityStats;

    if (stats.totalCredentials == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No passwords yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first credential to see password strength distribution',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Strength Distribution',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: stats.strongPasswords.toDouble(),
                        title: 'Strong',
                        color: Colors.green,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: stats.weakPasswords.toDouble(),
                        title: 'Weak',
                        color: Colors.orange,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: stats.compromisedPasswords.toDouble(),
                        title: 'Compromised',
                        color: Colors.red,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.3, duration: 600.ms, delay: 800.ms);
  }

  Widget _buildRecentActivity(
    BuildContext context,
    VaultProvider vaultProvider,
  ) {
    final recentCredentials = vaultProvider.credentials.take(5).toList();

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to vault
                    },
                    child: const Text('View All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentCredentials.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your recent credential changes will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...recentCredentials.map(
                (credential) => _buildActivityItem(context, credential),
              ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 900.ms)
        .slideY(begin: 0.3, duration: 600.ms, delay: 900.ms);
  }

  Widget _buildActivityItem(BuildContext context, Credential credential) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCredentialIcon(credential.type),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  credential.username,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(credential.updatedAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Add Credential',
                    Icons.add,
                    () {
                      // Navigate to add credential
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Generate Password',
                    Icons.vpn_key,
                    () {
                      // Navigate to password generator
                    },
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 1000.ms)
        .slideY(begin: 0.3, duration: 600.ms, delay: 1000.ms);
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCredentialIcon(CredentialType type) {
    switch (type) {
      case CredentialType.email:
        return Icons.email_outlined;
      case CredentialType.website:
        return Icons.web_outlined;
      case CredentialType.card:
        return Icons.credit_card_outlined;
      case CredentialType.social:
        return Icons.share_outlined;
      case CredentialType.other:
        return Icons.more_horiz_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
