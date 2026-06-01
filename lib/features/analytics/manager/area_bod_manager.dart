import 'package:flutter/foundation.dart';
import 'package:checkly/features/analytics/manager/area_bod_data.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart'
    show BodAgingBucket, ApDetailEntry, StoreBodSummary, CategoryStoreEntry;
import 'package:checkly/features/analytics/services/area_bod_api_service.dart';

class AreaBodManager extends ChangeNotifier {
  final AreaBodApiService _api;

  bool _isLoading = false;
  bool _isOffline = false;
  bool _isEmpty = false;
  String? _error;
  AreaBodResponse? _report;

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
  AreaAuditorProductivity? _auditorDetail;

  AreaBodManager(this._api);

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get isEmpty => _isEmpty;
  String? get error => _error;
  AreaBodResponse? get report => _report;

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
  AreaAuditorProductivity? get auditorDetail => _auditorDetail;

  void _update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> loadReport() async {
    _update(() {
      _isLoading = true;
      _isOffline = false;
      _isEmpty = false;
      _error = null;
    });

    try {
      final res = await _api.getReport();
      _update(() {
        _report = res;
        _isLoading = false;
        _isOffline = false;
        _isEmpty = false;
      });
    } catch (e) {
      _update(() {
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
      });
    }
  }

  Future<void> refreshReport() async {
    _update(() {
      _isLoading = true;
      _isOffline = false;
      _isEmpty = false;
      _error = null;
    });

    try {
      final res = _isLiveMode && _activeProvince != null
          ? await _api.getFilteredReport(
              _activeProvince!,
              _activeDistrict ?? '',
            )
          : await _api.getReport();
      _update(() {
        _report = res;
        _isLoading = false;
      });
    } catch (e) {
      _update(() {
        _isLoading = false;
        final errStr = e.toString();
        if (errStr.contains('DioException') || errStr.contains('connection')) {
          _isOffline = true;
        } else {
          _error = 'Something went wrong. Please try again.';
        }
      });
    }
  }

  Future<void> applyFilter(String province, String district) async {
    if (_isLoading) return;
    _update(() {
      _isLoading = true;
      _isLiveMode = true;
      _activeProvince = province;
      _activeDistrict = district;
      _error = null;
    });

    try {
      final res = await _api.getFilteredReport(province, district);
      _update(() {
        _report = res;
        _isLoading = false;
      });
    } catch (e) {
      _update(() {
        _isLoading = false;
        _report = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> clearFilter() async {
    _update(() {
      _isLiveMode = false;
      _activeProvince = null;
      _activeDistrict = null;
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.getReport();
      _update(() {
        _report = res;
        _isLoading = false;
      });
    } catch (e) {
      _update(() {
        _isLoading = false;
        _report = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> loadApDetails(BodAgingBucket bucket) async {
    if (_isApDetailLoading) return;
    _update(() {
      _isApDetailLoading = true;
      _error = null;
    });

    if (bucket == BodAgingBucket.all) {
      try {
        final List<List<ApDetailEntry>> results = await Future.wait([
          _api.getApBucketDetail('0-7d'),
          _api.getApBucketDetail('8-30d'),
          _api.getApBucketDetail('31-90d'),
          _api.getApBucketDetail('90d+'),
        ]);
        _update(() {
          _apDetails = results.expand((x) => x).toList()
            ..sort((a, b) => b.ageInDays.compareTo(a.ageInDays));
          _isApDetailLoading = false;
        });
        return;
      } catch (e) {
        _update(() {
          _isApDetailLoading = false;
          _apDetails = [];
          _error = 'Something went wrong. Please try again.';
        });
        return;
      }
    }

    try {
      final res = await _api.getApBucketDetail(bucket.toApiKey());
      _update(() {
        _apDetails = res;
        _isApDetailLoading = false;
      });
    } catch (e) {
      _update(() {
        _isApDetailLoading = false;
        _apDetails = [];
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> loadStoreDetail(String storeId) async {
    if (_isStoreDetailLoading) return;
    _update(() {
      _isStoreDetailLoading = true;
      _error = null;
    });

    try {
      final res = await _api.getStoreBodSummary(storeId);
      _update(() {
        _storeDetail = res;
        _isStoreDetailLoading = false;
      });
    } catch (e) {
      _update(() {
        _isStoreDetailLoading = false;
        _storeDetail = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> loadCategoryDetail(String name) async {
    if (_isCategoryDetailLoading) return;
    _update(() {
      _isCategoryDetailLoading = true;
      _error = null;
    });

    final trimmedName = name.trim();

    try {
      final res = await _api.getCategoryDetail(trimmedName);
      _update(() {
        _categoryDetail = res;
        _isCategoryDetailLoading = false;
      });
    } catch (e) {
      _update(() {
        _isCategoryDetailLoading = false;
        _categoryDetail = [];
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> loadAuditorDetail(String auditorName) async {
    if (_isAuditorDetailLoading) return;
    _update(() {
      _isAuditorDetailLoading = true;
      _error = null;
    });

    try {
      final productivityList = await _api.getAuditorProductivity();
      AreaAuditorProductivity? matched;
      for (final item in productivityList) {
        if (item.auditorName == auditorName) {
          matched = item;
          break;
        }
      }
      _update(() {
        _auditorDetail = matched;
        _isAuditorDetailLoading = false;
      });
    } catch (e) {
      _update(() {
        _isAuditorDetailLoading = false;
        _auditorDetail = null;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }
}
