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
  List<ApDetailEntry> _apDetails = [];

  bool _isStoreDetailLoading = false;
  StoreBodSummary? _storeDetail;

  bool _isCategoryDetailLoading = false;
  List<CategoryStoreEntry> _categoryDetail = [];

  bool _isAuditorDetailLoading = false;
  dynamic _auditorDetail;

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
  List<ApDetailEntry> get apDetails => _apDetails;

  bool get isStoreDetailLoading => _isStoreDetailLoading;
  StoreBodSummary? get storeDetail => _storeDetail;

  bool get isCategoryDetailLoading => _isCategoryDetailLoading;
  List<CategoryStoreEntry> get categoryDetail => _categoryDetail;

  bool get isAuditorDetailLoading => _isAuditorDetailLoading;
  dynamic get auditorDetail => _auditorDetail;


  Future<void> loadReport() async {
    _isLoading = true;
    _isOffline = false;
    _isEmpty = false;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[BOD] loadReport → calling _api.getReport()');
      final res = await _api.getReport();
      debugPrint('[BOD] loadReport → fromJson complete. trend.length=${res.trend.length}');
      _report = res;
      _isLoading = false;
      _isOffline = false;
      _isEmpty = false;
      debugPrint('[BOD] loadReport → notifyListeners()');
      notifyListeners();
    } catch (e, s) {
      debugPrint('[BOD] loadReport → CATCH: $e\n$s');
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

    if (_isLiveMode && _activeProvince != null) {
      try {
        final res = await _api.getFilteredReport(_activeProvince!, _activeDistrict ?? '');
        _report = res;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        _report = prevReport;
        final errStr = e.toString();
        if (errStr.contains('DioException') || errStr.contains('connection')) {
          _isOffline = true;
        } else {
          _error = 'Something went wrong. Please try again.';
        }
        notifyListeners();
      }
      return;
    }

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
    if (_isApDetailLoading) return;
    _isApDetailLoading = true;
    _error = null;
    notifyListeners();

    final trimmed = bucketName.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'all' || trimmed == 'open') {
      try {
        final List<List<ApDetailEntry>> results = await Future.wait([
          _api.getApBucketDetail('0-7d'),
          _api.getApBucketDetail('8-30d'),
          _api.getApBucketDetail('31-90d'),
          _api.getApBucketDetail('90d+'),
        ]);
        _apDetails = results.expand((x) => x).toList()
          ..sort((a, b) => b.ageInDays.compareTo(a.ageInDays));
        _isApDetailLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        _isApDetailLoading = false;
        _apDetails = [];
        _error = 'Something went wrong. Please try again.';
        notifyListeners();
        return;
      }
    }

    String normalized;
    if (trimmed.contains('0-7') || trimmed.contains('0-7d')) {
      normalized = '0-7d';
    } else if (trimmed.contains('8-30') || trimmed.contains('8-30d')) {
      normalized = '8-30d';
    } else if (trimmed.contains('31-90') || trimmed.contains('31-90d')) {
      normalized = '31-90d';
    } else if (trimmed.contains('90+') || trimmed.contains('90d')) {
      normalized = '90d+';
    } else if (trimmed.contains('0-30')) {
      normalized = '8-30d';
    } else if (trimmed.contains('31-60')) {
      normalized = '31-90d';
    } else if (trimmed.contains('61-90')) {
      normalized = '31-90d';
    } else {
      normalized = trimmed;
    }

    try {
      final res = await _api.getApBucketDetail(normalized);
      _apDetails = res;
      _isApDetailLoading = false;
      notifyListeners();
    } catch (e) {
      _isApDetailLoading = false;
      _apDetails = [];
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> loadStoreDetail(String storeId) async {
    if (_isStoreDetailLoading) return;
    _isStoreDetailLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getStoreBodSummary(storeId);
      _storeDetail = res;
      _isStoreDetailLoading = false;
      notifyListeners();
    } catch (e) {
      _isStoreDetailLoading = false;
      _storeDetail = null;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> loadCategoryDetail(String name) async {
    if (_isCategoryDetailLoading) return;
    _isCategoryDetailLoading = true;
    _error = null;
    notifyListeners();

    final trimmedName = name.trim();

    try {
      final res = await _api.getCategoryDetail(trimmedName);
      _categoryDetail = res;
      _isCategoryDetailLoading = false;
      notifyListeners();
    } catch (e) {
      _isCategoryDetailLoading = false;
      _categoryDetail = [];
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> loadAuditorDetail(String auditorName) async {
    if (_isAuditorDetailLoading) return;
    _isAuditorDetailLoading = true;
    _error = null;
    notifyListeners();

    try {
      final productivityList = await _api.getAuditorProductivity();
      dynamic matched;
      for (final item in productivityList) {
        if (item is Map && item['auditorName'] == auditorName) {
          matched = item;
          break;
        }
      }
      _auditorDetail = matched;
      _isAuditorDetailLoading = false;
      notifyListeners();
    } catch (e) {
      _isAuditorDetailLoading = false;
      _auditorDetail = null;
      _error = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }
}

