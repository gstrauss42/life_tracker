/// Screen breakpoints for responsive design.
/// 
/// - Mobile: width < 600
/// - Tablet: 600 <= width < 1200
/// - Desktop: width >= 1200
class Breakpoints {
  Breakpoints._();

  /// Mobile breakpoint (< 600px)
  static const double mobile = 600;

  /// Tablet breakpoint (600px - 1200px)
  static const double tablet = 1200;

  /// Check if width is mobile
  static bool isMobile(double width) => width < mobile;

  /// Check if width is tablet
  static bool isTablet(double width) => width >= mobile && width < tablet;

  /// Check if width is desktop
  static bool isDesktop(double width) => width >= tablet;

  /// Get the current layout type
  static LayoutType getLayoutType(double width) {
    if (width < mobile) return LayoutType.mobile;
    if (width < tablet) return LayoutType.tablet;
    return LayoutType.desktop;
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



