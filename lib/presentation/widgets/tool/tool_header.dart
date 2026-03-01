import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ToolHeader extends StatelessWidget {
  final String title;
  final String description;
  final List<Map<String, String>> breadcrumbs;

  const ToolHeader({
    super.key,
    required this.title,
    required this.description,
    required this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumbs
        Row(
          children: [
            for (var i = 0; i < breadcrumbs.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
                ),
              if (breadcrumbs[i]['href'] != null)
                InkWell(
                  onTap: () {
                    if (breadcrumbs[i]['href'] != null) {
                      Navigator.of(context).pushNamed(breadcrumbs[i]['href']!);
                    }
                  },
                  child: Text(
                    breadcrumbs[i]['label']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Text(
                  breadcrumbs[i]['label']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Title & Description
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
