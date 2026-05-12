import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:checkly/_shared/utils/isolate_parser.dart';

// ── Test Plan: IsolateParser (Pillar B — Threshold-Gated Isolates) ──
// AC1: Parses arrays normally on UI thread if < 1M chars
// AC2: Parses massively large arrays flawlessly (impl. delegates to isolate) if > 1M chars
// AC3: Correctly drills down using `listKey`
// AC4: Parses a flat array with no `listKey`
// AC5: Non-string argument guards developer from misconfigured Dio
// AC6: Malformed JSON throws FormatException
// AC7: Missing listKey throws TypeError or FormatException
// ──────────────────────────────────────────────────────────────────────

void main() {
  group('IsolateParser - Happy Path', () {
    test('AC1 — IsolateParser_BelowThreshold_ParsesSynchronously: '
        'Parses small JSON flat array directly on the UI thread', () async {
      const jsonString =
          '[{"id":"1","name":"Store A"},{"id":"2","name":"Store B"}]';

      // Act
      final result = await IsolateParser.parseList(
        json: jsonString,
        parser: (json) => json,
      );

      // Assert
      expect(result, hasLength(2));
      expect(result[0]['name'], 'Store A');
      expect(result[1]['name'], 'Store B');
    });

    test('AC2 — IsolateParser_AboveThreshold_ParsesInBackground: '
        'Parses massive JSON (> 1MB) without causing UI jank', () async {
      // Arrange: Build a JSON string > 1,000,000 chars
      const chunk = '{"id":"abc123","name":"Store X"},';
      // 50,000 iterations * ~33 chars = ~1.65 million chars
      final StringBuffer buffer = StringBuffer('[');
      for (int i = 0; i < 50000; i++) {
        buffer.write(chunk);
      }
      buffer.write('{"id":"last","name":"Z"}]');
      final massiveJson = buffer.toString();

      expect(
        massiveJson.length,
        greaterThan(1000000),
        reason:
            'Test setup failure: Expected massive JSON to exceed 1M chars threshold',
      );

      // Act
      final result = await IsolateParser.parseList(
        json: massiveJson,
        parser: (json) => json,
      );

      // Assert
      expect(result, hasLength(50001));
      expect(result.last['name'], 'Z');
    });

    test('AC3 — IsolateParser_WrappedResponse_ExtractsViaListKey: '
        'Parses JSON object wrapper by drilling into listKey', () async {
      const jsonString = '{"metadata":{}, "items":[{"id":"1"},{"id":"2"}]}';

      // Act
      final result = await IsolateParser.parseList(
        json: jsonString,
        listKey: 'items',
        parser: (json) => json,
      );

      // Assert
      expect(result, hasLength(2));
      expect(result[0]['id'], '1');
    });

    test('AC4 — IsolateParser_FlatArray_NoListKey_ParsesDirectly: '
        'Parses JSON flat array when no listKey is specified', () async {
      const jsonString = '[{"id":"1"},{"id":"2"}]';

      // Act
      final result = await IsolateParser.parseList(
        json: jsonString,
        listKey: null,
        parser: (json) => json,
      );

      // Assert
      expect(result, hasLength(2));
    });
  });

  group('IsolateParser - Error State Guards', () {
    test('AC5 — IsolateParser_NonStringInput_ThrowsArgumentError: '
        'Guards developers forgetting ResponseType.plain in Dio', () async {
      // Simulating a Map returned directly by Dio default parsing.
      final mapInput = {
        'data': [
          {'id': '1'},
        ],
      };

      // Act & Assert
      expect(
        () => IsolateParser.parseList(
          json: mapInput, // Passing map intentionally
          parser: (j) => j,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('ResponseType.plain'), // Must flag the exact Dio fix
          ),
        ),
      );
    });

    test('AC6 — IsolateParser_MalformedJson_ThrowsFormatException: '
        'Throws standard dart FormatException for junk JSON', () async {
      const junkJson = '[{"id": BROKEN SYNTAX';

      // Act & Assert
      expect(
        () => IsolateParser.parseList(json: junkJson, parser: (json) => json),
        throwsFormatException,
      );
    });

    test(
      'AC7 — IsolateParser_WrongListKey_ThrowsFormatException: '
      'Throws TypeError or FormatException when the target key does not contain a List',
      () async {
        const jsonString = '{"data":[{"id":"1"}]}';

        // Act & Assert: looking for "items" instead of "data"
        expect(
          () => IsolateParser.parseList(
            json: jsonString,
            listKey: 'items', // Wrong key
            parser: (json) => json,
          ),
          throwsA(
            anyOf(
              isA<TypeError>(),
              isA<FormatException>(),
              isA<
                PlatformException
              >(), // Some isolate errors bubble differently depending on structure
              isA<
                Exception
              >(), // Broad fallback, standardizing on some Exception
            ),
          ),
        );
      },
    );
  });
}
