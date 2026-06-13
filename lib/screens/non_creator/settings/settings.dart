import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/auth/create_account.dart';
import 'package:soundhive2/screens/auth/update_profile1.dart';
import '../../../components/success.dart';
import '../../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../theme/theme_provider.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  bool biometricEnabled = false;
  String pin = '';
  void onSubmit() async {
    try {
      final response = await ref.read(apiresponseProvider.notifier).createPin(
        context: context,
        pin: pin,
      );
      if(response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Success(
              image: 'images/success_profile.png',
              title: 'Pin Updated Successfully',
              subtitle: '',
            ),
          ),
        );
      }
    }
    catch(error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }

  }

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

            // _tile(
            //   context,
            //   icon: Icons.fingerprint,
            //   title: 'Finger Print / Face Unlock',
            //   trailing: Switch(
            //     value: biometricEnabled,
            //     onChanged: (v) =>
            //         setState(() => biometricEnabled = v),
            //   ),
            // ),

            const Divider(),

            // _tile(
            //   context,
            //   icon: Icons.lock_outline,
            //   title: 'Change Password',
            // ),
            //
            // const Divider(),

            _tile(
              context,
              icon: Icons.pin_outlined,
              title: 'Change Authenticator PIN',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PinSetupStep(
                      onBack: () => Navigator.pop(context),
                      onPinUpdated: (newPin) => setState(() => pin = newPin),
                      onSubmit: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
            ),
            _tile(
              context,
              icon: Icons.delete,
              title: 'Delete Account',
              color: Colors.red,  // 👈 add this
              onTap: () async {
                await ref
                    .read(apiresponseProvider.notifier)
                    .deleteAccount(context: context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  CreateAccount.id,
                      (_) => false,
                );
              },
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red),  // 👈 add color here too
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
        VoidCallback? onTap,
        Color? color,  // 👈 add this
      }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),           // 👈 apply color
      title: Text(title, style: TextStyle(color: color)),  // 👈 apply color
      trailing: trailing,
      onTap: onTap,
    );
  }
}
