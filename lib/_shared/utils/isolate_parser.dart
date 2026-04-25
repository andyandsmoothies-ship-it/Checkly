import 'dart:convert';
import 'package:flutter/foundation.dart';

// Top-level args class required by compute() — class methods cannot cross
// isolate boundaries in Dart.
class _ParseArgs<T> {
  final String payload;
  final T Function(Map<String, dynamic>) parser;
  final String? listKey;

  const _ParseArgs(this.payload, this.parser, [this.listKey]);
}

/// Top-level function required by compute() — must NOT be a class method.
List<T> _isolateParseTask<T>(_ParseArgs<T> args) {
  final decoded = jsonDecode(args.payload);

  final List<dynamic> jsonList;
  if (args.listKey != null && decoded is Map<String, dynamic>) {
    final value = decoded[args.listKey!];
    if (value is! List) {
      throw FormatException(
        'Key "${args.listKey}" does not map to a List in the JSON payload.',
      );
    }
    jsonList = value;
  } else if (decoded is List) {
    jsonList = decoded;
  } else {
    throw FormatException(
      'Payload is neither a JSON Array nor a Map containing listKey: ${args.listKey}',
    );
  }

  return jsonList.map((j) => args.parser(j as Map<String, dynamic>)).toList();
}

/// Threshold-gated JSON parser.
///
/// Parses a large JSON [String] payload in a background [Isolate] when the
/// payload exceeds 1MB (~1,000,000 UTF-16 code units). Below the threshold,
/// parsing happens synchronously on the calling thread to avoid isolate
/// spawn overhead.
///
/// **API Contract:** [json] MUST be a [String]. If [Dio] auto-parsed the
/// response (i.e. `ResponseType.plain` was omitted), an [ArgumentError] is
/// thrown immediately to surface the misconfiguration.
class IsolateParser {
  /// Rough 1MB proxy threshold (~1M UTF-16 characters).
  static const int _thresholdChars = 1000000;

  /// Parses a JSON list payload, offloading to a background isolate when needed.
  ///
  /// [json]     — Raw JSON [String]. Must NOT be a pre-parsed [Map] or [List].
  /// [parser]   — A top-level or static factory function (e.g. `TemplateDto.fromJson`).
  /// [listKey]  — Optional key to unwrap a paginated wrapper object (e.g. `'items'`).
  ///              If null, the payload must be a flat JSON array `[...]`.
  static Future<List<T>> parseList<T>({
    required dynamic json,
    required T Function(Map<String, dynamic>) parser,
    String? listKey,
  }) {
    // ── Guard: Must be a raw String. Throws synchronously for immediate feedback. ──
    if (json is! String) {
      throw ArgumentError(
        'IsolateParser requires a raw JSON String. '
        'Did you forget to set Options(responseType: ResponseType.plain) in Dio? '
        'Without it, Dio auto-parses the response and IsolateParser cannot function.',
      );
    }

    final payload = json;
    final args = _ParseArgs<T>(payload, parser, listKey);

    if (payload.length > _thresholdChars) {
      // Mega-sync: offload to a background isolate.
      return compute(_isolateParseTask<T>, args);
    } else {
      // Micro-sync: parse synchronously, avoid isolate spawn overhead.
      return Future.value(_isolateParseTask<T>(args));
    }
  }
}
