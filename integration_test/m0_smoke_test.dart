import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/app/app.dart';

/// M0 最小启动测试 —— 验证应用可启动并渲染占位页。
/// 在尚无真实流程时可暂不运行（由 verify.ps1 控制）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('应用启动并渲染 M0 占位页', (tester) async {
    await tester.pumpWidget(const XaocenApp());
    await tester.pump();

    expect(find.text('XAOCEN Reader v4'), findsOneWidget);
    expect(find.text('当前阶段：M0'), findsOneWidget);
  });
}
