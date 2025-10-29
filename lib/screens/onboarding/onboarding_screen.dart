import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to MachKey',
      subtitle: 'Your secure password manager',
      description:
          'Store all your passwords safely with end-to-end encryption. Only you can access your data.',
      icon: Icons.security,
      lightColor: AppTheme.primaryColor,
      darkColor: AppTheme.primaryLight,
    ),
    OnboardingPage(
      title: 'Zero-Knowledge Security',
      subtitle: 'Your data, your control',
      description:
          'All your passwords are encrypted on your device before being stored. We never see your data.',
      icon: Icons.lock_outline,
      lightColor: AppTheme.successColor,
      darkColor: const Color(0xFF4CAF50),
    ),
    OnboardingPage(
      title: 'Smart Password Generator',
      subtitle: 'Create strong passwords instantly',
      description:
          'Generate secure passwords with customizable options. Never use weak passwords again.',
      icon: Icons.vpn_key,
      lightColor: AppTheme.infoColor,
      darkColor: const Color(0xFF42A5F5),
    ),
    OnboardingPage(
      title: 'Security Audit',
      subtitle: 'Keep your accounts safe',
      description:
          'Get alerts for weak, reused, or compromised passwords. Stay one step ahead of threats.',
      icon: Icons.shield_outlined,
      lightColor: const Color(0xFFE53935),
      darkColor: const Color(0xFFEF5350),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPage = _pages[_currentPage];
    final pageColor = isDark ? currentPage.darkColor : currentPage.lightColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pageColor, pageColor.withValues(alpha: 0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60), // Placeholder for balance
                    SizedBox(
                      width: 60,
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final page = _pages[index];
                    final pageColor = isDark ? page.darkColor : page.lightColor;
                    return _buildPage(page, pageColor);
                  },
                ),
              ),

              // Page Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    if (_currentPage > 0)
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: _previousPage,
                          child: Text(
                            'Previous',
                            style: TextStyle(
                              fontFamily: Theme.of(
                                context,
                              ).textTheme.displayMedium?.fontFamily,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    // Next/Get Started Button
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: _currentPage == _totalPages - 1
                            ? _completeOnboarding
                            : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: pageColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _currentPage == _totalPages - 1
                              ? 'Get Started'
                              : 'Next',
                          style: TextStyle(
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.displaySmall?.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, Color pageColor) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
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
            child: Icon(page.icon, size: 60, color: pageColor),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 48),

          // Title
          Text(
                page.title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: 0.3, duration: 800.ms, delay: 200.ms),

          const SizedBox(height: 16),

          // Subtitle
          Text(
                page.subtitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 400.ms)
              .slideY(begin: 0.3, duration: 800.ms, delay: 400.ms),

          const SizedBox(height: 24),

          // Description
          Text(
                page.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: 800.ms, delay: 600.ms)
              .slideY(begin: 0.3, duration: 800.ms, delay: 600.ms),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.setOnboardingCompleted(true);

    // Call the callback to notify parent widget
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });
}
