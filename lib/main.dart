import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/layout/main_layout.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/all_tools/all_tools_screen.dart';
import 'presentation/screens/tools/merge_pdf_screen.dart';
import 'presentation/screens/tools/split_pdf_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/category/category_screen.dart';

// Very basic routing state for demo purposes without full GoRouter setup yet
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Helper function to handle navigation from bottom nav
    void handleNavigation(
      BuildContext context,
      String currentRoute,
      String targetRoute,
    ) {
      if (currentRoute == targetRoute) return;

      if (targetRoute == '/' ||
          targetRoute == '/all-tools' ||
          targetRoute == '/settings') {
        // For main tabs, clear stack so we don't build an infinite back-history
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(targetRoute, (route) => false);
      } else {
        Navigator.of(context).pushNamed(targetRoute);
      }
    }

    final routeName = settings.name;

    // Dynamic Routes
    if (routeName != null && routeName.startsWith('/category/')) {
      final slug = routeName.replaceFirst('/category/', '');
      return MaterialPageRoute(
        builder: (context) => MainLayout(
          currentRoute: routeName,
          onNavigate: (route) => handleNavigation(context, routeName, route),
          child: CategoryScreen(slug: slug),
        ),
      );
    }

    // Static Routes
    switch (routeName) {
      case '/':
        return MaterialPageRoute(
          builder: (context) => MainLayout(
            currentRoute: '/',
            onNavigate: (route) => handleNavigation(context, '/', route),
            child: const HomeScreen(),
          ),
        );
      case '/all-tools':
        return MaterialPageRoute(
          builder: (context) => MainLayout(
            currentRoute: '/all-tools',
            onNavigate: (route) =>
                handleNavigation(context, '/all-tools', route),
            child: const AllToolsScreen(),
          ),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (context) => MainLayout(
            currentRoute: '/settings',
            onNavigate: (route) =>
                handleNavigation(context, '/settings', route),
            child: const SettingsScreen(),
          ),
        );
      case '/tools/pdf/merge':
        return MaterialPageRoute(
          builder: (context) => MainLayout(
            currentRoute: '/tools/pdf/merge',
            onNavigate: (route) =>
                handleNavigation(context, '/tools/pdf/merge', route),
            child: const MergePdfScreen(),
          ),
        );
      case '/tools/pdf/split':
        return MaterialPageRoute(
          builder: (context) => MainLayout(
            currentRoute: '/tools/pdf/split',
            onNavigate: (route) =>
                handleNavigation(context, '/tools/pdf/split', route),
            child: const SplitPdfScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

void main() {
  runApp(const KitbaseApp());
}

class KitbaseApp extends StatefulWidget {
  const KitbaseApp({super.key});

  @override
  State<KitbaseApp> createState() => _KitbaseAppState();
}

class _KitbaseAppState extends State<KitbaseApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.system) {
        final brightness = View.of(
          context,
        ).platformDispatcher.platformBrightness;
        _themeMode = brightness == Brightness.dark
            ? ThemeMode.light
            : ThemeMode.dark;
      } else {
        _themeMode = _themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitbase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      // Provide theme toggle to the tree
      builder: (context, child) {
        return _ThemeProvider(
          toggleTheme: toggleTheme,
          themeMode: _themeMode,
          child: child!,
        );
      },
    );
  }
}

// Simple InheritedWidget to pass theme toggle down
class _ThemeProvider extends InheritedWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const _ThemeProvider({
    required this.toggleTheme,
    required this.themeMode,
    required super.child,
  });

  static _ThemeProvider of(BuildContext context) {
    final _ThemeProvider? result = context
        .dependOnInheritedWidgetOfExactType<_ThemeProvider>();
    assert(result != null, 'No _ThemeProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_ThemeProvider oldWidget) =>
      themeMode != oldWidget.themeMode;
}

// Extension to easily access theme toggle
extension ThemeExtension on BuildContext {
  void toggleTheme() => _ThemeProvider.of(this).toggleTheme();
  bool get isDarkMode {
    final mode = _ThemeProvider.of(this).themeMode;
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(this) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }
}
