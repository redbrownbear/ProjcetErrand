import 'package:flutter_test/flutter_test.dart';

import 'package:project_errand/main.dart';

void main() {
  testWidgets('Home screen shows headline and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const BureumApp());

    expect(find.textContaining('겸사겸사'), findsWidgets);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
  });
}
