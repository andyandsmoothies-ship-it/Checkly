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

  bool _isLiveMode = false;
  String? _activeProvince;
  String? _activeDistrict;

  bool _isApDetailLoading = false;
  List<dynamic> _apDetails = [];

  BodAnalyticsManager(this._api);

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get isEmpty => _isEmpty;
  String? get error => _error;
  BodReportResponse? get report => _report;

  bool get isLiveMode => _isLiveMode;
  String? get activeProvince => _activeProvince;
  String? get activeDistrict => _activeDistrict;

  bool get isApDetailLoading => _isApDetailLoading;
  List<dynamic> get apDetails => _apDetails;

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
      } else if (errStr.contains('DioException') ||
          errStr.contains('connection')) {
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

  Future<void> applyFilter(String province, String district) async {
    if (_isLoading) return;
    _isLoading = true;
    _isLiveMode = true;
    _activeProvince = province;
    _activeDistrict = district;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getFilteredReport(province, district);
      _report = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _report = null;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> clearFilter() async {
    _isLiveMode = false;
    _activeProvince = null;
    _activeDistrict = null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getReport();
      _report = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _report = null;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> loadApDetails(String bucketName) async {
    _isApDetailLoading = true;
    _apDetails = [];
    notifyListeners();

    // Simulate database lookup latency
    await Future.delayed(const Duration(milliseconds: 1000));

    // Generate mock details based on the bucketName
    if (bucketName == '0-30 Days') {
      _apDetails = [
        {
          'criteriaLabel': 'Temperature Logs',
          'storeName': 'Central Market',
          'managerName': 'Andy Manager',
          'overdueDays': 12,
        },
        {
          'criteriaLabel': 'Sanitization Station Check',
          'storeName': 'Siam Square',
          'managerName': 'Smoothie Manager',
          'overdueDays': 25,
        },
      ];
    } else if (bucketName == '31-60 Days') {
      _apDetails = [
        {
          'criteriaLabel': 'Fire Exit Clearance',
          'storeName': 'Outpost West',
          'managerName': 'Kate Manager',
          'overdueDays': 45,
        },
      ];
    } else if (bucketName == '61-90 Days') {
      _apDetails = [
        {
          'criteriaLabel': 'Daily Opening Routine',
          'storeName': 'Airport Express',
          'managerName': 'John Manager',
          'overdueDays': 75,
        },
      ];
    } else {
      _apDetails = [
        {
          'criteriaLabel': 'Weekly Equipment Calibration',
          'storeName': 'North Gate',
          'managerName': 'Lisa Manager',
          'overdueDays': 110,
        },
      ];
    }

    _isApDetailLoading = false;
    notifyListeners();
  }
}
