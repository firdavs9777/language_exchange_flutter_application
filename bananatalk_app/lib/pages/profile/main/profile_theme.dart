import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/main.dart';

class ProfileTheme extends ConsumerStatefulWidget {
  const ProfileTheme({super.key});

  @override
  _ProfileThemeState createState() => _ProfileThemeState();
}

class _ProfileThemeState extends ConsumerState<ProfileTheme> {
  @override
  Widget build(BuildContext context) {
    // Watch the themeProvider to get the current theme mode
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Theme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto switch toggle for system theme with enhanced color
            ListTile(
              title: const Text('Auto Switch (System Theme)'),
              trailing: Switch(
                value: themeMode == ThemeMode.system,
                onChanged: (bool value) {
                  final newMode = value ? ThemeMode.system : ThemeMode.light;
                  ref.read(themeProvider.notifier).state = newMode;
                },
                activeColor: Colors.blueAccent, // Active switch color
                inactiveThumbColor: Colors.grey, // Inactive thumb color
                inactiveTrackColor: Colors.grey[400], // Inactive track color
              ),
            ),
            const Divider(),
            Text('When enable it will follow your system theme settings'),
            Container(
              child: ListTile(
                title: const Text('Light Mode'),
                trailing: Checkbox(
                  value: themeMode == ThemeMode.light,
                  onChanged: (bool? value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).state =
                          value ? ThemeMode.light : ThemeMode.dark;
                    }
                  },
                ),
              ),
            ),

            Container(
              child: ListTile(
                title: const Text('Dark Mode'),
                trailing: Checkbox(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (bool? value) {
                    if (value != null) {
                      ref.read(themeProvider.notifier).state =
                          value ? ThemeMode.dark : ThemeMode.light;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
