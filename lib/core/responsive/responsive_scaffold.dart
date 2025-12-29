import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Navigation item configuration
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A responsive scaffold that switches between navigation patterns:
/// - Mobile (< 768px): BottomNavigationBar
/// - Tablet (768px - 1024px): NavigationRail (collapsible)
/// - Desktop (>= 1024px): Full sidebar with labels
class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.leading,
    this.floatingActionButton,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final Widget? leading;
  final Widget? floatingActionButton;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold>
    with SingleTickerProviderStateMixin {
  bool _isRailExtended = false;
  late final AnimationController _animationController;
  late final Animation<double> _railAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _railAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleRail() {
    setState(() {
      _isRailExtended = !_isRailExtended;
      if (_isRailExtended) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final layoutType = Breakpoints.getLayoutType(width);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (layoutType) {
        LayoutType.mobile => _buildMobileLayout(context),
        LayoutType.tablet => _buildTabletLayout(context),
        LayoutType.desktop => _buildDesktopLayout(context),
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: widget.destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // On smaller tablets, keep rail collapsed by default
    final shouldAllowExtend = screenWidth >= 900;

    return Scaffold(
      body: Row(
        children: [
          AnimatedBuilder(
            animation: _railAnimation,
            builder: (context, child) {
              // Ensure rail doesn't extend on smaller screens
              final isExtended = shouldAllowExtend && _isRailExtended;
              
              return NavigationRail(
                selectedIndex: widget.selectedIndex,
                onDestinationSelected: widget.onDestinationSelected,
                extended: isExtended,
                minExtendedWidth: 180,
                minWidth: 72,
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.primaryContainer,
                selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
                unselectedIconTheme: IconThemeData(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                selectedLabelTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leading != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: widget.leading,
                      ),
                    const SizedBox(height: 8),
                    if (shouldAllowExtend) _buildCollapseButton(colorScheme),
                  ],
                ),
                destinations: widget.destinations.map((d) {
                  return NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(
                      d.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          _buildFullSidebar(theme, colorScheme),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildCollapseButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: _toggleRail,
      icon: AnimatedRotation(
        turns: _isRailExtended ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.chevron_right, size: 20),
      ),
      tooltip: _isRailExtended ? 'Collapse' : 'Expand',
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildFullSidebar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 220,
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header with logo
          if (widget.leading != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  widget.leading!,
                  const SizedBox(width: 12),
                  Text(
                    'Life Tracker',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.destinations.length,
              itemBuilder: (context, index) {
                final destination = widget.destinations[index];
                final isSelected = widget.selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarItem(
                    icon: isSelected ? destination.selectedIcon : destination.icon,
                    label: destination.label,
                    isSelected: isSelected,
                    onTap: () => widget.onDestinationSelected(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primaryContainer
                : _isHovered
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: widget.isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: widget.isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



