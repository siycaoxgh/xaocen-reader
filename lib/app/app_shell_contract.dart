import 'package:flutter/material.dart';

/// Shared responsive contract for the app's first-level shell.
///
/// Windows and Android intentionally use the same destinations and breakpoint
/// decision.  Only the navigation chrome changes (sidebar versus bottom
/// navigation); secondary routes such as Reader are outside this contract.
abstract final class AppShellLayout {
  /// Preserve the existing shell behavior: widths at or above 720 logical px
  /// use the desktop/sidebar presentation.
  static const double desktopBreakpoint = 720;

  static bool isDesktop(BuildContext context) =>
      isDesktopWidth(MediaQuery.sizeOf(context).width);

  static bool isDesktopWidth(double width) => width >= desktopBreakpoint;

  static const destinations = <AppShellDestination>[
    AppShellDestination('首页', Icons.home_outlined, Icons.home),
    AppShellDestination('书架', Icons.menu_book_outlined, Icons.menu_book),
    AppShellDestination('我的', Icons.person_outline, Icons.person),
  ];
}

@immutable
class AppShellDestination {
  const AppShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
