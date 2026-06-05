import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/geocoding_service.dart';

class MockDio extends Mock implements Dio {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockDio mockDio;
  late MockConnectivityService mockConnectivity;
  late RealGeocodingService service;

  setUp(() {
    mockDio = MockDio();
    mockConnectivity = MockConnectivityService();
    
    // Always online by default
    when(() => mockConnectivity.isOnline).thenReturn(true);
    when(() => mockDio.options).thenReturn(BaseOptions());
    
    service = RealGeocodingService(
      dio: mockDio,
      connectivityService: mockConnectivity,
    );
  });

  tearDown(() {
    reset(mockDio);
    reset(mockConnectivity);
  });

  group('GeocodingService (Slice 3 ATDD/TDD)', () {
    test('geocode - Happy Path - returns LatLng', () async {
      // Arrange
      final responseData = [
        {
          "lat": "10.7758",
          "lon": "106.7018",
          "display_name": "Nguyen Hue, Quan 1, Ho Chi Minh, Vietnam"
        }
      ];
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: responseData,
      ));

      // Act
      final result = await service.geocode('123 Nguyen Hue');

      // Assert
      expect(result, isNotNull);
      expect(result!.latitude, 10.7758);
      expect(result.longitude, 106.7018);
    });

    test('reverseGeocode - Happy Path - returns GeocodedAddress', () async {
      // Arrange
      final responseData = {
        "address": {
          "city": "Hồ Chí Minh",
          "suburb": "Quận 1",
          "road": "Nguyễn Huệ"
        },
        "display_name": "Nguyễn Huệ, Quận 1, Hồ Chí Minh"
      };
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: responseData,
      ));

      // Act
      final result = await service.reverseGeocode(const LatLng(10.7758, 106.7018));

      // Assert
      expect(result, isNotNull);
      expect(result!.province, "Hồ Chí Minh");
      expect(result.district, "Quận 1");
      expect(result.street, "Nguyễn Huệ");
      expect(result.displayName, "Nguyễn Huệ, Quận 1, Hồ Chí Minh");
    });

    test('reverseGeocode - Empty/Not Found - returns null when in water', () async {
      // Arrange
      // API returns a 200 but no address dictionary or missing province
      final responseData = {
        "error": "Unable to geocode"
      };
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200, // Nominatim often returns 200 with an error object
        data: responseData,
      ));

      // Act
      final result = await service.reverseGeocode(const LatLng(0, 0));

      // Assert
      expect(result, isNull);
    });

    test('geocode - Offline State - throws GeocodingException', () async {
      // Arrange
      when(() => mockConnectivity.isOnline).thenReturn(false);

      // Act & Assert
      expect(
        () => service.geocode('123 Nguyen Hue'),
        throwsA(isA<GeocodingException>().having((e) => e.message, 'message', contains('offline'))),
      );
      verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    test('geocode - Rate Limited (HTTP 429) - throws specific exception', () async {
      // Arrange
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 429),
      ));

      // Act & Assert
      expect(
        () => service.geocode('Spam Address'),
        throwsA(isA<GeocodingException>()
          .having((e) => e.isRateLimited, 'isRateLimited', true)
        ),
      );
    });

    test('geocode - Throttle/Debounce - blocks rapid successive calls', () async {
      // Arrange
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate network
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: [],
        );
      });

      // Act & Assert
      // First call should work
      final future1 = service.geocode('Address 1');
      // Immediate second call should throw throttle exception
      expect(
        () => service.geocode('Address 2'),
        throwsA(isA<GeocodingException>().having((e) => e.message, 'message', contains('Too many requests'))),
      );

      await future1;
      
      // Clear throttle state to prevent test interference
      service.clearThrottle();
    });

    test('geocode - Request Headers - includes custom User-Agent', () async {
      // Arrange
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((invocation) async {
        final options = invocation.namedArguments[#options] as Options?;
        expect(options, isNotNull);
        expect(options!.headers?['User-Agent'], isNotNull);
        expect(options.headers?['User-Agent'], contains('Checkly'));
        
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: [],
        );
      });

      // Act
      await service.geocode('Test Header');

      // Assert
      verify(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).called(1);
    });
  });
}
