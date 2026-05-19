import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'fab_menu.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/tasks', '/notes', '/calendar', '/settings'];
  static const _labels = ['Tasks', 'Notes', 'Calendar', 'Settings'];
  static const _icons = [Icons.check_box, Icons.note, Icons.calendar_month, Icons.settings];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return _tabs.indexWhere((t) => location.startsWith(t)).clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: List.generate(
          4,
          (i) => NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
      floatingActionButton: const FabMenu(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
