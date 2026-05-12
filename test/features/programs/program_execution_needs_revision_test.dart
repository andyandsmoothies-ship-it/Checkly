import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/programs/manager/program_manager.dart';
import 'package:checkly/features/programs/model/program_assignment_dto.dart';
import 'package:checkly/features/programs/pages/program_execution_page.dart';

class MockProgramManager extends Mock implements ProgramManager {}

void main() {
  late MockProgramManager mockManager;

  setUp(() {
    mockManager = MockProgramManager();
    GetIt.instance.registerSingleton<ProgramManager>(mockManager);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'ProgramExecutionPage shows Needs Revision banner when status is needs_revision',
    (WidgetTester tester) async {
      // Arrange
      const assignmentId = 'assign-123';
      final assignment = ProgramAssignmentDto(
        id: assignmentId,
        programId: 'prog-123',
        activeSubmissionId: null,
        templateId: null,
        programTitle: 'Fix Endcap Display',
        category: 'Merchandising',
        deadline: DateTime.now().add(const Duration(days: 1)),
        status: 'needs_revision',
        rejectionComment:
            'The signage is crooked. Please retake the photo after straightening it.',
        createdAt: DateTime.now(),
      );

      when(
        () => mockManager.loadAssignment(assignmentId),
      ).thenAnswer((_) async => assignment);

      // Act
      await tester.pumpWidget(
        MaterialApp(home: ProgramExecutionPage(assignmentId: assignmentId)),
      );

      // Wait for async load to finish
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Needs Revision'), findsOneWidget);
      expect(
        find.text(
          'The signage is crooked. Please retake the photo after straightening it.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Ensure the main form is still rendered
      expect(find.text('Fix Endcap Display'), findsWidgets);
    },
  );
}
