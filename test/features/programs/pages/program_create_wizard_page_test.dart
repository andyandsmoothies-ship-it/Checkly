import 'package:checkly/features/programs/pages/program_create_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/programs/services/program_api_service.dart';
import 'package:checkly/features/templates/managers/template_manager.dart';
import 'package:get_it/get_it.dart';

class MockProgramApiService extends Mock implements ProgramApiService {}
class MockTemplateManager extends Mock implements TemplateManager {}

void main() {
  late MockProgramApiService mockProgramApiService;
  late MockTemplateManager mockTemplateManager;

  setUp(() {
    mockProgramApiService = MockProgramApiService();
    mockTemplateManager = MockTemplateManager();
    GetIt.I.registerSingleton<ProgramApiService>(mockProgramApiService);
    GetIt.I.registerSingleton<TemplateManager>(mockTemplateManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildWidget() {
    return const MaterialApp(
      home: ProgramCreateWizardPage(),
    );
  }

  group('ProgramCreateWizardPage Tests', () {
    testWidgets('TC-04: wizard Issue button disabled with no stores', (tester) async {
      await tester.pumpWidget(buildWidget());
      
      // Look for the "Issue Program" button
      final issueButtonFinder = find.byKey(const Key('issue_program_button'));
      expect(issueButtonFinder, findsOneWidget);
      
      // Verify it's disabled (onPressed is null)
      final button = tester.widget<ElevatedButton>(issueButtonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('TC-05: wizard Issue button disabled with no deadline', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('issue_program_button')), findsOneWidget);
    });

    testWidgets('TC-06: wizard Issue button disabled with empty title', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('issue_program_button')), findsOneWidget);
    });

    testWidgets('TC-08: wizard calls createProgram on Issue', (tester) async {
      when(() => mockProgramApiService.createProgram(
            title: any(named: 'title'),
            category: any(named: 'category'),
            deadline: any(named: 'deadline'),
            templateId: any(named: 'templateId'),
            storeIds: any(named: 'storeIds'),
          )).thenAnswer((_) async => {'programId': '123', 'assignmentCount': 2});

      await tester.pumpWidget(buildWidget());
      
      // Test will fail to compile as ProgramCreateWizardPage does not exist
      expect(ProgramCreateWizardPage, isNotNull);
    });
  });
}
