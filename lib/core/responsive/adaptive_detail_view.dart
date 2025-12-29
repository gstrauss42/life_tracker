import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Controller for managing detail panel state
class DetailPanelController extends ChangeNotifier {
  Widget? _content;
  String? _heroTag;
  bool _isOpen = false;

  Widget? get content => _content;
  String? get heroTag => _heroTag;
  bool get isOpen => _isOpen;

  void open(Widget content, {String? heroTag}) {
    _content = content;
    _heroTag = heroTag;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    notifyListeners();
    // Clear content after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _content = null;
      _heroTag = null;
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
/// - Full-screen page (mobile)
/// - Side panel (tablet/desktop)
class AdaptiveDetailLayout extends StatelessWidget {
  const AdaptiveDetailLayout({
    super.key,
    required this.controller,
    required this.masterContent,
    this.detailWidth = 480,
    this.minMasterWidth = 400,
  });

  final DetailPanelController controller;
  final Widget masterContent;
  final double detailWidth;
  final double minMasterWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final layoutType = Breakpoints.getLayoutType(width);

    return DetailPanelProvider(
      controller: controller,
      child: layoutType.isMobile
          ? masterContent
          : _buildMasterDetailLayout(context, width),
    );
  }

  Widget _buildMasterDetailLayout(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // Calculate panel width based on screen size
        final maxDetailWidth = (screenWidth * 0.45).clamp(detailWidth, 600.0);
        
        return Row(
          children: [
            // Master content
            Expanded(
              child: masterContent,
            ),
            // Detail panel with slide animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: controller.isOpen ? maxDetailWidth : 0,
              child: controller.isOpen
                  ? _buildDetailPanel(theme, colorScheme)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailPanel(ThemeData theme, ColorScheme colorScheme) {
    return Container(
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
          child: controller.content ?? const SizedBox.shrink(),
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



