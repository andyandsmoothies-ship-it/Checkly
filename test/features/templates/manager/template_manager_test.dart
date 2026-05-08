import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/_shared/database/dao/template_dao.dart';
import 'package:checkly/features/templates/manager/template_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/features/templates/services/template_api_service.dart';

import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:get_it/get_it.dart';

class MockTemplateApiService extends Mock implements TemplateApiService {}
class MockTemplateDao extends Mock implements TemplateDao {}
class MockDatabaseService extends Mock implements DatabaseService {}
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TemplateManager manager;
  late MockTemplateApiService mockApi;
  late MockTemplateDao mockDao;
  late MockDatabaseService mockDbService;

  setUp(() {
    mockApi = MockTemplateApiService();
    mockDao = MockTemplateDao();
    mockDbService = MockDatabaseService();
    
    when(() => mockDbService.db).thenReturn(MockAppDatabase());
    
    GetIt.I.reset();
    GetIt.I.registerSingleton<DatabaseService>(mockDbService);
    
    manager = TemplateManager(api: mockApi, dao: mockDao);
  });

  group('TemplateManager Tests', () {
    final t1 = TemplateDto(
      id: 't1',
      title: 'T1',
      type: 'checklist',
      version: 1,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final tree1 = TemplateTreeDto(
      id: 't1',
      title: 'T1',
      type: 'checklist',
      version: 1,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      groups: [],
    );

    test('loadTemplates uses cache first, then API', () async {
      when(() => mockDao.getAllTemplates()).thenAnswer((_) async => [t1]);
      when(() => mockApi.getTemplates()).thenAnswer((_) async => [t1]);
      when(() => mockDao.upsertTemplates(any())).thenAnswer((_) async => {});

      await manager.loadTemplates();

      verify(() => mockDao.getAllTemplates()).called(1);
      verify(() => mockApi.getTemplates()).called(1);
      verify(() => mockDao.upsertTemplates(any())).called(1);
      expect(manager.templates.value, [t1]);
      expect(manager.error, isNull);
    });

    test('loadTemplates handles offline gracefully if cache exists', () async {
      when(() => mockDao.getAllTemplates()).thenAnswer((_) async => [t1]);
      when(() => mockApi.getTemplates()).thenThrow(Exception('offline'));

      await manager.loadTemplates();

      verify(() => mockDao.getAllTemplates()).called(1);
      verify(() => mockApi.getTemplates()).called(1);
      expect(manager.templates.value, [t1]);
      expect(manager.error, isNull); // Falls back to cache silently
    });

    test('loadTemplates sets error if API fails and cache is empty', () async {
      when(() => mockDao.getAllTemplates()).thenAnswer((_) async => []);
      when(() => mockApi.getTemplates()).thenThrow(Exception('offline'));

      await manager.loadTemplates();

      expect(manager.templates.value, isEmpty);
      expect(manager.error, 'Failed to load templates (offline)');
    });

    test('loadTemplateTree uses cache first, then API', () async {
      when(() => mockDao.getTemplateTree('t1')).thenAnswer((_) async => tree1);
      when(() => mockApi.getTemplateTree('t1')).thenAnswer((_) async => tree1);
      when(() => mockDao.upsertTemplates(any())).thenAnswer((_) async => {});
      when(() => mockDao.upsertGroups(any(), any(), any())).thenAnswer((_) async => {});

      await manager.loadTemplateTree('t1');

      verify(() => mockDao.getTemplateTree('t1')).called(1);
      verify(() => mockApi.getTemplateTree('t1')).called(1);
      verify(() => mockDao.upsertTemplates(any())).called(1);
      expect(manager.selectedTemplate.value, tree1);
    });

    test('deleteTemplate updates API and local state', () async {
      manager.templates.value = [t1];
      when(() => mockApi.deleteTemplate('t1')).thenAnswer((_) async => {});

      await manager.deleteTemplate('t1');

      verify(() => mockApi.deleteTemplate('t1')).called(1);
      expect(manager.templates.value, isEmpty);
    });
  });
}
