/// Screen breakpoints for responsive design.
/// 
/// - Compact: width < 360 (very small phones)
/// - Mobile: 360 <= width < 768
/// - Tablet: 768 <= width < 1024
/// - Desktop: width >= 1024
class Breakpoints {
  Breakpoints._();

  /// Compact breakpoint (< 360px) - very small phones
  static const double compact = 360;
  
  /// Mobile breakpoint (< 768px)
  static const double mobile = 768;

  /// Tablet breakpoint (768px - 1024px)
  static const double tablet = 1024;
  
  /// Minimum width to show side panel (need room for both master + detail)
  static const double sidePanelMinWidth = 840;

  /// Check if width is compact (very narrow)
  static bool isCompact(double width) => width < compact;
  
  /// Check if width is mobile (includes compact)
  static bool isMobile(double width) => width < mobile;

  /// Check if width is tablet
  static bool isTablet(double width) => width >= mobile && width < tablet;

  /// Check if width is desktop
  static bool isDesktop(double width) => width >= tablet;
  
  /// Check if detail panel can fit alongside master content
  static bool canShowDetailPanel(double width) => width >= sidePanelMinWidth;

  /// Get the current layout type
  static LayoutType getLayoutType(double width) {
    if (width < mobile) return LayoutType.mobile;
    if (width < tablet) return LayoutType.tablet;
    return LayoutType.desktop;
  }
  
  /// Get optimal number of columns for tracking cards grid
  static int getTrackingGridColumns(double width) {
    if (width <= 0 || !width.isFinite) return 1;
    if (width < compact) return 1;
    if (width < 480) return 2;  // Narrow mobile: 2 columns
    if (width < tablet) return 2;  // Mobile/small tablet: 2 columns
    return 3;  // Desktop: 3 columns
  }
  
  /// Get responsive padding based on width
  static double getContentPadding(double width) {
    if (width < compact) return 12;
    if (width < mobile) return 16;
    if (width < tablet) return 20;
    return 24;
  }
  
  /// Get responsive spacing based on width
  static double getCardSpacing(double width) {
    if (width < compact) return 8;
    if (width < mobile) return 12;
    return 16;
  }
}

/// Layout types for responsive design
enum LayoutType {
  mobile,
  tablet,
  desktop,
}

/// Extension for convenient layout checks
extension LayoutTypeExtension on LayoutType {
  bool get isMobile => this == LayoutType.mobile;
  bool get isTablet => this == LayoutType.tablet;
  bool get isDesktop => this == LayoutType.desktop;
  bool get isTabletOrDesktop => this == LayoutType.tablet || this == LayoutType.desktop;
}



