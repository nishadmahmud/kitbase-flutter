import 'package:flutter/material.dart';
import 'mobile_bottom_nav.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final Function(String) onNavigate;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to scroll behind bottom nav
      body: child,
      bottomNavigationBar: MobileBottomNav(
        currentRoute: currentRoute,
        onNavigate: onNavigate,
      ),
    );
  }
}
