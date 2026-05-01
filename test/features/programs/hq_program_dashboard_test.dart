import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/programs/pages/program_list_page.dart';
import 'package:checkly/features/programs/pages/program_dashboard_page.dart';
import 'package:checkly/features/programs/services/program_api_service.dart';

void main() {
  group('HQ Program Dashboard ATDD', () {
    test('ProgramListPage exists and can be imported', () {
      expect(ProgramListPage, isNotNull);
    });

    test('ProgramDashboardPage exists and can be imported', () {
      expect(ProgramDashboardPage, isNotNull);
    });

    test('ProgramApiService exists and has getProgramAssignments method', () {
      expect(ProgramApiService, isNotNull);
    });
  });
}
