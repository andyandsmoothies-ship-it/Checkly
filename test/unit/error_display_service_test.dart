import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:checkly/_shared/exceptions/app_error.dart';
import 'package:checkly/_shared/exceptions/error_dictionary.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/locator.dart';

void main() {
  group('AppError & ErrorDictionary Tests', () {
    test('TC-01: Valid ProblemDetails code: "conflict"', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 409,
          data: {
            "type": "https://tools.ietf.org/html/rfc9110#section-15.5.10",
            "title": "Conflict",
            "status": 409,
            "detail": "State conflict",
            "code": "conflict",
          },
        ),
      );

      // Act
      final appError = AppError.fromDioException(dioException);
      final displayMessage = ErrorDictionary.lookup(appError.code);

      // Assert
      expect(appError.code, 'conflict');
      expect(
        displayMessage,
        'This record was changed by someone else. Refresh and try again.',
      );
    });

    test('TC-02: Unknown error code fallback', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 500,
          data: {"code": "new_mystery_code"},
        ),
      );

      // Act
      final appError = AppError.fromDioException(dioException);
      final displayMessage = ErrorDictionary.lookup(appError.code);

      // Assert
      expect(appError.code, 'new_mystery_code');
      // Should fallback to unknown
      expect(displayMessage, 'Something went wrong. Please try again.');
    });

    test('TC-03: Non-JSON response (HTML from NGINX)', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 502,
          data: "<html><body><h1>502 Bad Gateway</h1></body></html>",
        ),
      );

      // Act
      final appError = AppError.fromDioException(dioException);
      final displayMessage = ErrorDictionary.lookup(appError.code);

      // Assert
      expect(appError.code, 'network_error');
      expect(
        displayMessage,
        "We couldn't connect. Check your connection and try again.",
      );
    });

    test('TC-04: Connection timeout', () {
      // Arrange
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        type: DioExceptionType.connectionTimeout,
      );

      // Act
      final appError = AppError.fromDioException(dioException);

      // Assert
      expect(appError.code, 'network_timeout');
    });
  });

  group('ErrorDisplayService Tests', () {
    late GlobalKey<NavigatorState> mockNavigatorKey;

    setUp(() {
      mockNavigatorKey = GlobalKey<NavigatorState>();
    });

    testWidgets('TC-05: onRetry callback provided', (tester) async {
      // Arrange: Setup a basic widget tree with ScaffoldMessenger and NavigatorKey
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: mockNavigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      final service = ErrorDisplayService(mockNavigatorKey);
      final appError = AppError(code: 'network_timeout', message: 'Timeout');
      bool retryCalled = false;

      // Act
      service.show(
        appError,
        onRetry: () {
          retryCalled = true;
        },
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('TC-06: Offline expected (sync failure)', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: mockNavigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      final service = ErrorDisplayService(mockNavigatorKey);
      final appError = AppError(
        code: 'network_timeout',
        message: 'Timeout',
        isOfflineExpected: true,
      );

      // Act
      service.show(appError);
      await tester.pump();

      // Assert
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason:
            'No SnackBar should be shown when offline is expected for network errors.',
      );
    });

    testWidgets('TC-07: Duplicate error spam (debounce)', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: mockNavigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      final service = ErrorDisplayService(mockNavigatorKey);
      final appError = AppError(code: 'server_error', message: 'Error');

      // Act
      service.show(appError);
      service.show(appError);
      service.show(appError);
      service.show(appError);
      service.show(appError);
      await tester.pump();

      // Assert
      // We check how many SnackBars are queued or currently displayed.
      // Usually, find.byType(SnackBar) should find exactly 1 if debounced correctly.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    test('TC-08: Service registers in get_it', () {
      // Arrange & Act
      // We assume locator setup doesn't blow up if we call it for testing.
      // However, usually we don't call the real configureDependencies in pure unit tests
      // without mocking the rest. But per the contract: di<ErrorDisplayService>() returns a non-null instance.
      try {
        configureDependencies();
      } catch (_) {
        // Ignore other setup errors, we just want to check if ErrorDisplayService is registered
      }

      // Assert
      expect(
        di.isRegistered<ErrorDisplayService>(),
        isTrue,
        reason: 'ErrorDisplayService should be registered in locator.',
      );
    });
  });
}
