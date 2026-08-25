import 'package:flutter_test/flutter_test.dart';

import 'package:project_errand/main.dart';

void main() {
  testWidgets('Home screen shows title and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const PumApp());

    expect(find.text('오늘 뭐 할까?'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
  });
}
