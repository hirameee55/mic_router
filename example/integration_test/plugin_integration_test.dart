import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mic_router/mic_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getMicInfo test', (WidgetTester tester) async {
    final MicRouter plugin = MicRouter();
    final Map<String, dynamic> version = await plugin.getMicInfo();
    expect(version.isNotEmpty, true);
  });
}
