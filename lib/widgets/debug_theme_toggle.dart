import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DebugThemeToggle extends StatelessWidget {
  const DebugThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return FloatingActionButton(
      mini: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      onPressed: () async {
        await themeProvider.toggleTheme();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Theme: ${themeProvider.themeMode == ThemeMode.light
                  ? 'Light'
                  : themeProvider.themeMode == ThemeMode.dark
                  ? 'Dark'
                  : 'System'}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Icon(
        Theme.of(context).brightness == Brightness.dark
            ? Icons.light_mode
            : Icons.dark_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
