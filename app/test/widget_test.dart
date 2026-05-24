import 'package:flutter_test/flutter_test.dart';

import 'package:foodie_bee/main.dart';

void main() {
  testWidgets('App renders Foodie Bee text', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodieBeeApp());

    expect(find.text('Foodie Bee'), findsOneWidget);
  });
}
