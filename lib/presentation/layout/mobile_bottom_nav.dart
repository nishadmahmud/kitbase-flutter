import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final String route;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class MobileBottomNav extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const MobileBottomNav({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  static const List<BottomNavItem> items = [
    BottomNavItem(label: 'Home', icon: Icons.home_outlined, route: '/'),
    BottomNavItem(
      label: 'Tools',
      icon: LucideIcons.layoutGrid,
      route: '/all-tools',
    ),
    BottomNavItem(
      label: 'Settings',
      icon: LucideIcons.settings,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xE6020617)
                : const Color(0xE6FFFFFF), // 90% opacity gray-950 / white
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF1e293b)
                    : const Color(0xFFe2e8f0),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                final isActive = currentRoute == item.route;
                return Expanded(
                  child: InkWell(
                    onTap: () => onNavigate(item.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isActive
                              ? (isDark
                                    ? const Color(0xFF3b82f6)
                                    : const Color(
                                        0xFF2563eb,
                                      )) // blue-500 / blue-600
                              : (isDark
                                    ? const Color(0xFF94a3b8)
                                    : const Color(
                                        0xFF64748b,
                                      )), // gray-400 / gray-500
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? (isDark
                                      ? const Color(0xFF3b82f6)
                                      : const Color(0xFF2563eb))
                                : (isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF64748b)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
