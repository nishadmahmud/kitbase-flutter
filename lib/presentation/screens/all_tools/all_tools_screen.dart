import 'package:flutter/material.dart';
import 'package:kitbase_flutter/core/constants/tools_registry.dart';
import 'package:kitbase_flutter/presentation/widgets/cards.dart';

class AllToolsScreen extends StatelessWidget {
  const AllToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'All Tools',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse every tool available on Kitbase.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF475569),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Categories and Tools
                ...ToolsRegistry.categories.map((cat) {
                  final tools = ToolsRegistry.tools
                      .where((t) => t.category == cat.slug)
                      .toList();

                  if (tools.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1f2937)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFe5e7eb),
                                ),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                ],
                              ),
                              child: Icon(cat.icon, size: 22, color: cat.color),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${tools.length} tools',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF9ca3af)
                                        : const Color(0xFF6b7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tools Grid (dynamic height)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: tools.map((tool) {
                            return FractionallySizedBox(
                              widthFactor: 0.48, // 2 columns
                              child: ToolCard(
                                tool: tool,
                                onTap: () {
                                  Navigator.of(context).pushNamed(tool.href);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
