import 'package:flutter_test/flutter_test.dart';
import 'package:vlink/main.dart';

void main() {
  testWidgets('V-LINK smoke test', (WidgetTester tester) async {
    // Fixed: Changed from VLinkApp() to VconnApp() to match your main.dart definition exactly
    await tester.pumpWidget(const VconnApp());
    expect(find.byType(VconnApp), findsOneWidget);
  });
}
