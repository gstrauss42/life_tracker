import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

/// Main application shell with navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const List<NavigationRailDestination> _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: Text('Today'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: Text('Analytics'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            extended: MediaQuery.of(context).size.width > 800,
            minExtendedWidth: 180,
            destinations: _destinations,
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
            selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
            unselectedIconTheme: IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            selectedLabelTextStyle: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildLogo(theme),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.favorite,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}
