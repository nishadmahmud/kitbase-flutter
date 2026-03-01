import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kitbase_flutter/main.dart'; // for toggleTheme and isDarkMode

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticsEnabled = true;

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://kitbase.co');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch website')),
        );
      }
    }
  }

  void _triggerHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your app preferences.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF475569),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Preferences Section
                Text(
                  'Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  context: context,
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  title: 'Theme Mode',
                  subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (val) {
                      _triggerHaptic();
                      context.toggleTheme();
                    },
                    activeThumbColor: theme.primaryColor,
                  ),
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context: context,
                  icon: LucideIcons.smartphone,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrate on interactions',
                  trailing: Switch(
                    value: _hapticsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _hapticsEnabled = val;
                      });
                      if (val) HapticFeedback.lightImpact();
                    },
                    activeThumbColor: theme.primaryColor,
                  ),
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 48),

                // About Section
                Text(
                  'About',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  context: context,
                  icon: LucideIcons.info,
                  title: 'App Version',
                  trailing: Text(
                    '1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF6b7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    _triggerHaptic();
                    _launchWebsite();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: _buildSettingsTile(
                    context: context,
                    icon: LucideIcons.globe,
                    title: 'Website',
                    subtitle: 'kitbase.co',
                    trailing: Icon(
                      LucideIcons.externalLink,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF6b7280),
                    ),
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151920) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1f2937) : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF6b7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
