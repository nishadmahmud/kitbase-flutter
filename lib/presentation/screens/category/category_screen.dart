import 'package:flutter/material.dart';
import '../../../core/constants/tools_registry.dart';
import '../../widgets/cards.dart';

class CategoryScreen extends StatelessWidget {
  final String slug;

  const CategoryScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find the category
    final categoryIndex = ToolsRegistry.categories.indexWhere(
      (c) => c.slug == slug,
    );
    if (categoryIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Category not found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/all-tools'),
                child: const Text('Browse all tools'),
              ),
            ],
          ),
        ),
      );
    }
    final category = ToolsRegistry.categories[categoryIndex];

    // Filter tools
    final tools = ToolsRegistry.tools.where((t) => t.category == slug).toList();

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Let GridBackground show through MainLayout
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF4b5563),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: isDark ? const Color(0xFFf3f4f6) : const Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          16,
          24,
          64,
        ), // Extra bottom padding for MobileBottomNav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs (optional matching web)
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false),
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF6b7280),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('›', style: TextStyle(color: Colors.grey)),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/all-tools', (route) => false),
                  child: Text(
                    'All Tools',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9ca3af)
                          : const Color(0xFF6b7280),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('›', style: TextStyle(color: Colors.grey)),
                ),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFe5e7eb)
                        : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hero Banner
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1f2937)
                      : const Color(0xFFe5e7eb),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1f2937)
                          : const Color(0xFFf9fafb),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFf3f4f6),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        category.icon,
                        size: 32,
                        color: category.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${tools.length} tools available · ${category.tags.join(", ")}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? const Color(0xFF9ca3af)
                                : const Color(0xFF6b7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tools Grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: tools.map((tool) {
                return FractionallySizedBox(
                  widthFactor: 0.47, // ~2 columns
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
      ),
    );
  }
}
