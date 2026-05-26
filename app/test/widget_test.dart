import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_bee/main.dart';

void main() {
  testWidgets('App renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodieBeeApp());
    expect(find.byType(FoodieBeeApp), findsOneWidget);
  });
}
