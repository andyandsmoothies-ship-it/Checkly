import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'pending_submission.dart';
import 'delta_pull_result.dart';
import 'pending_submission_risk.dart';
import 'sync_api.dart';

typedef _PageResult<T> = ({List<T> items, bool hasMore});

Future<List<T>> _paginatedFetch<T>({
  required Future<_PageResult<T>> Function(int page) fetchPage,
  int startPage = 1,
  int? maxPages,
}) async {
  final allItems = <T>[];
  var page = startPage;

  while (true) {
    if (maxPages != null && page > maxPages) {
      break;
    }

    final pageResult = await fetchPage(page);
    allItems.addAll(pageResult.items);

    if (!pageResult.hasMore) {
      break;
    }

    page++;
  }

  return allItems;
}

/// Production implementation of [SyncApi] for real network sync.
class SyncApiAdapter implements SyncApi {
  final Dio _dio;

  SyncApiAdapter(this._dio);

  /// Returns true if [url] is a local device file path that must not reach
  /// the backend database.
  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    // ignore: avoid_print
    debugPrint('[SyncApi] pushSubmission key=${submission.idempotencyKey}');

    // Decode the stored JSON string and strip local file paths from photoUrl
    // fields so they never pollute the backend Postgres database.
    final payload = Map<String, dynamic>.from(
      jsonDecode(submission.payload) as Map,
    );

    final answers = payload['answers'];
    if (answers is List) {
      for (final a in answers) {
        if (a is Map<String, dynamic>) {
          final url = a['photoUrl'];
          if (url is String && _isLocalPath(url)) {
            a['photoUrl'] = null;
          }
        }
      }
    }

    // Extract routing metadata â€” never send this field to the backend.
    final targetId = payload.remove('targetSubmissionId') as String?;

    if (targetId != null && targetId.isNotEmpty) {
      // Finalize an existing server-side DRAFT submission.
      // Backend: PUT /api/submissions/{id}/finalize (FinalizeSubmission.cs)
      await _dio.put(
        '/submissions/$targetId/finalize',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
    } else {
      // Fresh new audit â€” use idempotent POST.
      await _dio.post(
        '/submissions',
        data: payload,
        options: Options(
          headers: {'X-Idempotency-Key': submission.idempotencyKey},
          contentType: Headers.jsonContentType,
        ),
      );
    }
  }

  @override
  Future<DeltaPullResult> pullDeltas({
    DateTime? cursorUpdatedAt,
    String? cursorId,
    String? storeId,
  }) async {
    final params = <String, dynamic>{};
    if (cursorUpdatedAt != null) {
      params['cursorUpdatedAt'] = cursorUpdatedAt.toUtc().toIso8601String();
    }
    if (cursorId != null) params['cursorId'] = cursorId;
    if (storeId != null) params['storeId'] = storeId;

    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/submissions',
      queryParameters: params,
    );

    final data = response.data;
    if (data == null) {
      return DeltaPullResult(
        // SA-3: Never fall back to device clock. A device with a future-dated clock
        // (e.g., 2029) would set the cursor years ahead, causing permanent empty pulls.
        // Use the previous cursor unchanged, or a known safe floor as last resort.
        serverTimestamp: cursorUpdatedAt ?? DateTime.utc(2020),
      );
    }

    final items = data['items'] as List<dynamic>? ?? [];
    final hasNextPage = data['hasNextPage'] as bool? ?? false;

    // SA-3: Start from previous cursor. If no cursor exists (first sync) and the
    // response is empty, use a safe floor (2020) instead of device clock.
    // Device clock may be years ahead on NTP-unsynchronised field devices.
    DateTime nextTimestamp = cursorUpdatedAt ?? DateTime.utc(2020);
    if (items.isNotEmpty) {
      final lastItem = items.last as Map<String, dynamic>;
      if (lastItem['updatedAt'] != null) {
        nextTimestamp = DateTime.parse(lastItem['updatedAt'] as String);
      } else if (lastItem['createdAt'] != null) {
        nextTimestamp = DateTime.parse(lastItem['createdAt'] as String);
      }
    }

    return DeltaPullResult(
      serverTimestamp: nextTimestamp,
      hasNextPage: hasNextPage,
      submissions: items,
    );
  }

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) {
    const pageSize = 100;
    const maxPages = 10; // Safety cap: 10 pages x 100 = 1000 risks max

    return _paginatedFetch<dynamic>(
      maxPages: maxPages,
      fetchPage: (page) async {
        final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
        if (since != null) {
          params['since'] = since.toIso8601String();
        }

        final response = await _dio.get<Map<String, dynamic>>(
          '/global-risks',
          queryParameters: params,
        );

        final list = response.data?['items'] as List<dynamic>? ?? [];
        return (items: list, hasMore: list.length >= pageSize);
      },
    );
  }

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
    await _dio.post(
      '/submissions/${risk.submissionId}/risks',
      data: {'globalRiskId': risk.globalRiskId},
    );
  }

  @override
  Future<List<dynamic>> pullProgramAssignments() {
    const pageSize = 50;
    const maxPages = 20; // Safety cap: 20 pages x 50 = 1000 assignments max

    return _paginatedFetch<dynamic>(
      maxPages: maxPages,
      fetchPage: (page) async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': page, 'pageSize': pageSize},
        );

        final data = response.data;
        if (data == null) {
          return (items: const <dynamic>[], hasMore: false);
        }

        final list = data['items'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;
        final hasMore = list.isNotEmpty && (page * pageSize) < total;
        return (items: list, hasMore: hasMore);
      },
    );
  }
}
