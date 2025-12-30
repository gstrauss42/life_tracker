import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Enum to track what type of panel is open
enum OpenPanelType { none, food, social, exercise }

/// Controller for managing detail panel state
class DetailPanelController extends ChangeNotifier {
  Widget? _content;
  String? _heroTag;
  bool _isOpen = false;
  OpenPanelType _panelType = OpenPanelType.none;
  
  /// Builder function to recreate the panel content for full-screen mode
  Widget Function(VoidCallback onClose)? _contentBuilder;

  Widget? get content => _content;
  String? get heroTag => _heroTag;
  bool get isOpen => _isOpen;
  OpenPanelType get panelType => _panelType;
  Widget Function(VoidCallback onClose)? get contentBuilder => _contentBuilder;

  void open(
    Widget content, {
    String? heroTag,
    OpenPanelType panelType = OpenPanelType.none,
    Widget Function(VoidCallback onClose)? contentBuilder,
  }) {
    _content = content;
    _heroTag = heroTag;
    _panelType = panelType;
    _contentBuilder = contentBuilder;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    _panelType = OpenPanelType.none;
    notifyListeners();
    // Clear content after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _content = null;
      _heroTag = null;
      _contentBuilder = null;
    });
  }

  void toggle(Widget content, {String? heroTag}) {
    if (_isOpen) {
      close();
    } else {
      open(content, heroTag: heroTag);
    }
  }
}

/// Inherited widget for accessing DetailPanelController
class DetailPanelProvider extends InheritedNotifier<DetailPanelController> {
  const DetailPanelProvider({
    super.key,
    required DetailPanelController controller,
    required super.child,
  }) : super(notifier: controller);

  static DetailPanelController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DetailPanelProvider>();
    assert(provider != null, 'DetailPanelProvider not found in context');
    return provider!.notifier!;
  }

  static DetailPanelController? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DetailPanelProvider>();
    return provider?.notifier;
  }
}

/// Adaptive layout that shows detail content as:
/// - Full-screen page (mobile/narrow)
/// - Side panel (tablet/desktop with enough width)
/// 
/// Handles breakpoint crossing: if panel is open and width shrinks below
/// threshold, automatically converts to full-screen.
class AdaptiveDetailLayout extends StatefulWidget {
  const AdaptiveDetailLayout({
    super.key,
    required this.controller,
    required this.masterContent,
    this.detailWidth = 400,
    this.minMasterWidth = 320,
  });

  final DetailPanelController controller;
  final Widget masterContent;
  final double detailWidth;
  final double minMasterWidth;

  @override
  State<AdaptiveDetailLayout> createState() => _AdaptiveDetailLayoutState();
}

class _AdaptiveDetailLayoutState extends State<AdaptiveDetailLayout> with WidgetsBindingObserver {
  double? _previousWidth;
  bool _isTransitioningToFullScreen = false;
  bool _isFullScreenRouteActive = false;
  Widget Function(VoidCallback onClose)? _activeContentBuilder;
  OpenPanelType _activePanelType = OpenPanelType.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Screen size changed - check if we need to convert panel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBreakpointCrossing();
      }
    });
  }

  void _checkBreakpointCrossing() {
    final width = MediaQuery.of(context).size.width;
    final canShowPanel = Breakpoints.canShowDetailPanel(width);
    final couldShowPanel = _previousWidth != null && Breakpoints.canShowDetailPanel(_previousWidth!);
    
    // Crossing from wide (can show panel) to narrow (can't show panel)
    if (couldShowPanel && !canShowPanel && widget.controller.isOpen && !_isTransitioningToFullScreen) {
      _convertToFullScreen();
    }
    
    // Crossing from narrow (can't show panel) to wide (can show panel)
    // If full-screen route is active, pop it and open as side panel
    if (!couldShowPanel && canShowPanel && _isFullScreenRouteActive && _activeContentBuilder != null) {
      _convertToSidePanel();
    }
    
    _previousWidth = width;
  }

  void _convertToFullScreen() {
    final contentBuilder = widget.controller.contentBuilder;
    if (contentBuilder == null) return;
    
    _isTransitioningToFullScreen = true;
    _activeContentBuilder = contentBuilder;
    _activePanelType = widget.controller.panelType;
    
    // Close the side panel
    widget.controller.close();
    
    // Push full-screen version
    _isFullScreenRouteActive = true;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (pageContext, animation, secondaryAnimation) {
          return Scaffold(
            body: SafeArea(
              child: contentBuilder(() {
                if (pageContext.mounted) {
                  Navigator.of(pageContext).maybePop();
                }
              }),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ).then((_) {
      _isTransitioningToFullScreen = false;
      _isFullScreenRouteActive = false;
      _activeContentBuilder = null;
      _activePanelType = OpenPanelType.none;
    });
  }
  
  void _convertToSidePanel() {
    final contentBuilder = _activeContentBuilder;
    final panelType = _activePanelType;
    if (contentBuilder == null) return;
    
    // Pop the full-screen route
    _isFullScreenRouteActive = false;
    Navigator.of(context).maybePop();
    
    // Open as side panel after a brief delay to let the pop complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.open(
          contentBuilder(() => widget.controller.close()),
          panelType: panelType,
          contentBuilder: contentBuilder,
        );
      }
    });
    
    _activeContentBuilder = null;
    _activePanelType = OpenPanelType.none;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    _previousWidth ??= width;
    
    final canShowPanel = Breakpoints.canShowDetailPanel(width);

    return DetailPanelProvider(
      controller: widget.controller,
      child: canShowPanel
          ? _buildMasterDetailLayout(context, width)
          : widget.masterContent,
    );
  }

  Widget _buildMasterDetailLayout(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // Calculate panel width based on screen size
        double maxDetailWidth;
        if (screenWidth < 1000) {
          maxDetailWidth = 360;
        } else if (screenWidth < 1200) {
          maxDetailWidth = 420;
        } else {
          maxDetailWidth = (screenWidth * 0.4).clamp(widget.detailWidth, 540.0);
        }
        
        // Ensure we leave enough room for master content
        final availableForDetail = screenWidth - widget.minMasterWidth;
        if (availableForDetail < maxDetailWidth) {
          maxDetailWidth = availableForDetail.clamp(300.0, maxDetailWidth);
        }
        
        return Row(
          children: [
            Expanded(child: widget.masterContent),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: widget.controller.isOpen ? maxDetailWidth : 0,
              child: widget.controller.isOpen
                  ? _buildDetailPanel(theme, colorScheme, maxDetailWidth)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailPanel(ThemeData theme, ColorScheme colorScheme, double panelWidth) {
    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.controller.content ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Helper function to show detail content adaptively
void showDetailAdaptive({
  required BuildContext context,
  required Widget content,
  String? heroTag,
  String? title,
}) {
  final width = MediaQuery.of(context).size.width;
  final layoutType = Breakpoints.getLayoutType(width);

  if (layoutType.isMobile) {
    // Push full-screen page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DetailPage(
          title: title,
          heroTag: heroTag,
          child: content,
        ),
      ),
    );
  } else {
    // Open in side panel
    final controller = DetailPanelProvider.maybeOf(context);
    if (controller != null) {
      controller.open(content, heroTag: heroTag);
    } else {
      // Fallback to modal if no controller found
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 500,
        ),
        builder: (_) => content,
      );
    }
  }
}

/// Close detail panel or pop page
void closeDetailAdaptive(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final layoutType = Breakpoints.getLayoutType(width);

  if (layoutType.isMobile) {
    Navigator.of(context).pop();
  } else {
    final controller = DetailPanelProvider.maybeOf(context);
    controller?.close();
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({
    this.title,
    this.heroTag,
    required this.child,
  });

  final String? title;
  final String? heroTag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: title != null
            ? Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: child,
    );
  }
}



