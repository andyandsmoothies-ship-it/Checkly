import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AdminApiService apiService;
  late MockDio dio;

  setUp(() {
    dio = MockDio();
    apiService = AdminApiService(dio);
  });

  group('AdminApiService — PBAC Slice 2: Capability Metadata', () {
    test(
      'getCapabilityCatalogFull returns both capabilities and metadata map',
      () async {
        // Arrange
        final responsePayload = {
          'capabilities': ['templates:create'],
          'capabilityMetadata': {
            'templates:create': {
              'label': 'Create Templates',
              'group': 'Templates',
              'description': '...',
            },
          },
        };

        when(
          () => dio.get(
            '/admin/capabilities/catalog',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: responsePayload,
            statusCode: 200,
          ),
        );

        // Act
        final (caps, meta) = await apiService.getCapabilityCatalogFull();

        // Assert
        expect(caps, equals(['templates:create']));
        expect(meta.containsKey('templates:create'), isTrue);

        final templateCreateMeta = meta['templates:create']!;
        expect(templateCreateMeta.label, equals('Create Templates'));
        expect(templateCreateMeta.group, equals('Templates'));
      },
    );
  });
}
