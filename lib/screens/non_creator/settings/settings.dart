import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/theme_provider.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  bool biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeModeProvider);

    // 2. Determine if we are currently in dark mode
    // We check if the mode is explicitly .dark
    final isDark = themeState.themeMode == ThemeMode.dark;

    // print('Settings screen - ThemeMode: $themeMode, isDark: $isDark, isDarkTheme: $isDarkTheme');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text(
              'APPEARANCE',
              style: Theme.of(context).textTheme.labelMedium,
            ),

            _tile(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              trailing: Switch(
                value: isDark,
                onChanged: (value) async {
                  print('Switch toggled to: $value');
                  await ref.read(themeModeProvider.notifier).toggleTheme(value);
                },
              ),
            ),

            const Divider(),

            const SizedBox(height: 24),

            Text(
              'SECURITY',
              style: Theme.of(context).textTheme.labelMedium,
            ),

            _tile(
              context,
              icon: Icons.fingerprint,
              title: 'Finger Print / Face Unlock',
              trailing: Switch(
                value: biometricEnabled,
                onChanged: (v) =>
                    setState(() => biometricEnabled = v),
              ),
            ),

            const Divider(),

            _tile(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
            ),

            const Divider(),

            _tile(
              context,
              icon: Icons.pin_outlined,
              title: 'Change Authenticator PIN',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context, {
        required IconData icon,
        required String title,
        Widget? trailing,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(child: Text(title)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
