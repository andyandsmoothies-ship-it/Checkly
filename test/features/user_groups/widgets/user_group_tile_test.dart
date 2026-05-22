import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/user_groups/widgets/user_group_tile.dart';
import 'package:checkly/features/user_groups/model/user_group_dto.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';

void main() {
  group('UserGroupTile Widget Tests', () {
    testWidgets('UG-WID-TILE-01: Tile renders correctly with description', (
      tester,
    ) async {
      const group = UserGroupDto(
        id: '1',
        name: 'Audit Team A',
        description: 'Primary auditors for north division',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserGroupTile(group: group)),
        ),
      );

      expect(find.byType(StrokeCard), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.text('Audit Team A'), findsOneWidget);
      expect(find.text('Primary auditors for north division'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets(
      'UG-WID-TILE-02: Tile does not render subtitle when description is null or empty',
      (tester) async {
        const groupNoDesc = UserGroupDto(
          id: '2',
          name: 'Audit Team B',
          description: null,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: UserGroupTile(group: groupNoDesc)),
          ),
        );

        expect(find.text('Audit Team B'), findsOneWidget);
        final subtitleFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data != 'Audit Team B',
        );
        expect(subtitleFinder, findsNothing);
      },
    );
  });
}
