import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Home_Screen/modern_home_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool notificationsEnabled = true; // TODO: Get from storage/preferences
    bool locationEnabled = true; // TODO: Get from storage/preferences
    final useModernHome = ref.watch(useModernHomeScreenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive ride updates and alerts',
              value: notificationsEnabled,
              onChanged: (value) {
                // TODO: Save notification preference
                notificationsEnabled = value;
              },
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader('Location'),
            _buildSwitchTile(
              title: 'Location Services',
              subtitle: 'Allow app to access your location',
              value: locationEnabled,
              onChanged: (value) {
                // TODO: Request location permission
                locationEnabled = value;
              },
            ),
            const SizedBox(height: 24),

            // App Section
            _buildSectionHeader('App'),
            _buildSwitchTile(
              title: 'Modern Home Screen',
              subtitle: 'Use new modern home layout',
              value: useModernHome,
              onChanged: (value) {
                ref.read(useModernHomeScreenProvider.notifier).state = value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                        ? 'Switched to modern home screen' 
                        : 'Switched to classic home screen'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () {
                // TODO: Implement language selection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language selection coming soon')),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.dark_mode,
              title: 'Theme',
              subtitle: 'Dark',
              onTap: () {
                // TODO: Implement theme selection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme selection coming soon')),
                );
              },
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('About'),
            _buildMenuTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.2',
              onTap: () {
                // TODO: Show version details
              },
            ),
            _buildMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              onTap: () {
                // TODO: Navigate to privacy policy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy policy coming soon')),
                );
              },
            ),
            _buildMenuTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'View terms and conditions',
              onTap: () {
                // TODO: Navigate to terms of service
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms of service coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

