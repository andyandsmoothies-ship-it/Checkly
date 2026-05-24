import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/analytics/services/bod_analytics_api_service.dart';
import 'package:checkly/_shared/services/interaction_manager.dart';

class BodAnalyticsManager extends ChangeNotifier {
  final BodAnalyticsApiService _api;

  bool _isLoading = false;
  bool _isOffline = false;
  bool _isEmpty = false;
  String? _error;
  BodReportResponse? _report;

  BodAnalyticsManager(this._api);

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get isEmpty => _isEmpty;
  String? get error => _error;
  BodReportResponse? get report => _report;

  Future<void> loadReport() async {
    _isLoading = true;
    _isOffline = false;
    _isEmpty = false;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getReport();
      _report = res;
      _isLoading = false;
      _isOffline = false;
      _isEmpty = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _report = null;
      final errStr = e.toString();
      if (errStr.contains('404')) {
        _isEmpty = true;
      } else if (errStr.contains('DioException') || errStr.contains('connection')) {
        _isOffline = true;
      } else {
        _error = 'Something went wrong. Please try again.';
      }
      notifyListeners();
    }
  }

  Future<void> refreshReport() async {
    final prevReport = _report;
    final prevComputedAt = prevReport?.computedAt;
    _isLoading = true;
    _isOffline = false;
    _isEmpty = false;
    _error = null;
    notifyListeners();

    try {
      await _api.triggerRefresh();

      int attempts = 0;
      const maxAttempts = 12;
      bool updated = false;

      while (attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 5));
        attempts++;
        try {
          final newReport = await _api.getReport();
          if (newReport.computedAt != prevComputedAt) {
            _report = newReport;
            _isLoading = false;
            updated = true;
            notifyListeners();
            break;
          }
        } catch (e) {
          // ignore transient poll failures
        }
      }

      if (!updated) {
        _isLoading = false;
        _report = prevReport;
        GetIt.instance<InteractionManager>().showWarningToast(
          'Data computation is taking longer than expected. Please check back shortly.',
        );
        notifyListeners();
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('429')) {
        _isLoading = false;
        GetIt.instance<InteractionManager>().showWarningToast(
          'Rate limit exceeded. Please try again later.',
        );
        notifyListeners();
      } else {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
        notifyListeners();
      }
    }
  }
}
