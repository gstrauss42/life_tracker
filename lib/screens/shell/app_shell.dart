import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../home/home_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

/// Main application shell with responsive navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  late final DetailPanelController _detailController;

  static const List<NavDestination> _destinations = [
    NavDestination(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      label: 'Today',
    ),
    NavDestination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Analytics',
    ),
    NavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _detailController = DetailPanelController();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Widget _getScreen(int index) {
    return switch (index) {
      0 => HomeScreen(detailController: _detailController),
      1 => const AnalyticsScreen(),
      2 => const SettingsScreen(),
      _ => HomeScreen(detailController: _detailController),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        // Close detail panel when switching tabs
        if (_detailController.isOpen) {
          _detailController.close();
        }
      },
      destinations: _destinations,
      leading: _buildLogo(theme),
      body: AdaptiveDetailLayout(
        controller: _detailController,
        masterContent: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _getScreen(_selectedIndex),
        ),
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
