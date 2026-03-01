import 'package:flutter/material.dart';
import 'package:kitbase_flutter/core/constants/tools_registry.dart';
import 'package:kitbase_flutter/presentation/widgets/cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final popularTools = ToolsRegistry.getPopularTools();
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Text(
                  'All your everyday tools.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 36,
                    height: 1.1,
                  ),
                ),
                Text(
                  'One clean place.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 36,
                    height: 1.1,
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF64748b)
                        : const Color(0xFF94a3b8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PDF, images, text, and developer utilities - fast, private, and free. No uploads, no ads, just pure utility.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF475569),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Popular Tools
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Popular',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Tools used by thousands every day',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/all-tools');
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: popularTools.take(4).map((tool) {
                    return FractionallySizedBox(
                      widthFactor:
                          0.48, // slightly under 50% to account for spacing
                      child: ToolCard(
                        tool: tool,
                        onTap: () {
                          Navigator.of(context).pushNamed(tool.href);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),

                // Categories
                Text(
                  'Browse Categories',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ToolsRegistry.categories.map((category) {
                    return FractionallySizedBox(
                      widthFactor: 0.48, // 2 columns
                      child: CategoryCard(
                        category: category,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed('/category/${category.slug}');
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
