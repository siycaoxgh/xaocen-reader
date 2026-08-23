import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app_shell_contract.dart';

void main() {
  test('shell keeps one shared desktop breakpoint', () {
    expect(
      AppShellLayout.isDesktopWidth(AppShellLayout.desktopBreakpoint - .01),
      isFalse,
    );
    expect(
      AppShellLayout.isDesktopWidth(AppShellLayout.desktopBreakpoint),
      isTrue,
    );
  });

  test('shell exposes the stable first-level destinations in order', () {
    expect(
      AppShellLayout.destinations.map((destination) => destination.label),
      ['首页', '书架', '我的'],
    );
    expect(AppShellLayout.destinations, hasLength(3));
  });
}
