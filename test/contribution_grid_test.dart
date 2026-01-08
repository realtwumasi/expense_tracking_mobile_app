import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expenseapp/widgets/contribution_grid.dart';

void main() {
  testWidgets('ContributionGrid wraps correctly (7 items per col)', (WidgetTester tester) async {
    // 1. Setup
    final dailySpending = <DateTime, double>{};
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContributionGrid(
            dailySpending: dailySpending,
            onDateTap: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 2. Find the widgets. The grid creates Tooltips wrapped in GestureDetectors.
    // The items are mapped from 'days'.
    final gestureDetectors = find.byType(GestureDetector);
    expect(gestureDetectors, findsWidgets);

    // 3. Check layout positions
    // Item 0 (start date)
    final box0 = tester.getRect(gestureDetectors.at(0));
    // Item 1
    final box1 = tester.getRect(gestureDetectors.at(1));
    // Item 7 (The 8th item). If 7 items per column, this should be in the SECOND column (Right of box0).
    final box7 = tester.getRect(gestureDetectors.at(7));

    print('Box0: $box0');
    print('Box1: $box1');
    print('Box7: $box7');

    // Box1 should be below Box0
    expect(box1.top, greaterThan(box0.top), reason: 'Item 1 should be below Item 0');
    expect(box1.left, equals(box0.left), reason: 'Item 1 should be in same column as Item 0');

    // Box7 should be to the right of Box0 (New Column)
    // If it is below Box6 (same column), then Top > Box0.top and Left == Box0.left
    if (box7.left == box0.left) {
      fail('Item 7 (8th item) is in the same column as Item 0. Grid has >= 8 rows!');
    }
  });
}
