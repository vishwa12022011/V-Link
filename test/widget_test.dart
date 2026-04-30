import 'package:flutter_test/flutter_test.dart';
import 'package:vlink/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VLinkApp());
    expect(find.byType(VLinkApp), findsOneWidget);
  });
}
