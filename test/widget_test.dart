import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/main.dart';

void main() {
  testWidgets('App loads LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScamShieldApp());
    expect(find.text('ScamShield'), findsOneWidget);
  });
}