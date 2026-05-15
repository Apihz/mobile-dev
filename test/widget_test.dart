import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app_1/app.dart';

void main() {
  testWidgets('Bottom nav switches between 4 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const KanbanBoardApp());

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.view_kanban_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Board'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Planner'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Team'), findsOneWidget);
  });
}
