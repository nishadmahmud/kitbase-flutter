import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/tools_registry.dart';

class ToolHeader extends StatelessWidget {
  final ToolModel tool;

  const ToolHeader({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final category = ToolsRegistry.categories.firstWhere(
      (c) => c.slug == tool.category,
      orElse: () => ToolsRegistry.categories.first,
    );

    final breadcrumbs = [
      {'label': "All Tools", 'href': "/all-tools"},
      {'label': category.name, 'href': "/category/${category.slug}"},
      {'label': tool.name},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        if (Navigator.canPop(context))
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.arrowLeft,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Breadcrumbs
        Row(
          children: [
            for (var i = 0; i < breadcrumbs.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Colors.grey,
                  ),
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
          tool.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tool.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
