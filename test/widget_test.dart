import 'package:flutter_test/flutter_test.dart';
import 'package:ikram_gaming_hub/main.dart';

void main() {
  testWidgets('IkramGamingHubApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IkramGamingHubApp());
    expect(find.byType(IkramGamingHubApp), findsOneWidget);
  });
}
