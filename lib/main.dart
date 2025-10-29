import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/debug_theme_toggle.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await SupabaseService.initialize();
  await StorageService().initialize();

  runApp(const MachK3yApp());
}

class MachK3yApp extends StatelessWidget {
  const MachK3yApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MachKey',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppWrapper(),
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - try biometric unlock
      _tryBiometricUnlock();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only try if user is authenticated but vault is locked
    if (authProvider.isAuthenticated && !authProvider.isVaultUnlocked) {
      final isBiometricEnabled = await authProvider.isBiometricUnlockEnabled();
      if (isBiometricEnabled) {
        // Attempt biometric unlock
        await authProvider.unlockVaultWithBiometrics();
      }
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final completed = await storageService.isOnboardingCompleted();
    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = completed;
        _isLoading = false;
      });
    }
  }

  void _onOnboardingCompleted() {
    setState(() {
      _hasCompletedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        Widget screen;

        // If user is authenticated, skip onboarding
        if (authProvider.isAuthenticated) {
          if (!authProvider.isVaultUnlocked) {
            screen = const VaultLockScreen();
          } else {
            screen = const DashboardScreen();
          }
        } else {
          // User is not authenticated - show onboarding if not completed
          if (!_hasCompletedOnboarding) {
            screen = OnboardingScreen(onCompleted: _onOnboardingCompleted);
          } else {
            screen = const LoginScreen();
          }
        }

        // Wrap with Stack to add debug FAB overlay
        return Stack(
          children: [
            screen,
            Positioned(bottom: 16, right: 16, child: const DebugThemeToggle()),
          ],
        );
      },
    );
  }
}

class VaultLockScreen extends StatefulWidget {
  const VaultLockScreen({super.key});

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _hasTriedBiometric = false;

  @override
  void initState() {
    super.initState();
    // Try biometric unlock when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    if (_hasTriedBiometric) return;

    setState(() {
      _hasTriedBiometric = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final isBiometricEnabled = await authProvider.isBiometricUnlockEnabled();
    if (isBiometricEnabled) {
      final result = await authProvider.unlockVaultWithBiometrics();
      if (!result.success) {
        setState(() {
          _hasTriedBiometric = false;
        });
      }
    } else {
      setState(() {
        _hasTriedBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
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
                  child: Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your master password to unlock your vault',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Password Input
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
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Master Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _unlockVault(),
                  ),
                ),

                const SizedBox(height: 24),

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _unlockVault,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
                  ),
                ),

                const SizedBox(height: 16),

                // Biometric Unlock Button (manual trigger)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return FutureBuilder<bool>(
                      future: authProvider.isBiometricUnlockEnabled(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true && !_hasTriedBiometric) {
                          return TextButton(
                            onPressed: _isLoading
                                ? null
                                : _unlockWithBiometrics,
                            child: Text(
                              'Unlock with Biometrics',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Logout Button
                TextButton(
                  onPressed: _logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlockVault() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.unlockVault(_passwordController.text);

    if (!mounted) return;

    if (result.success) {
      // Vault unlocked successfully
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to unlock vault'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.unlockVaultWithBiometrics();

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Biometric unlock failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
