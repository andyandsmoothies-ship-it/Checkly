/// Collects all validation errors discovered during a single `_validate()` pass.
///
/// Keys follow the pattern:
/// - `'template'` — template-level errors (title, no sections, ghost template)
/// - `'section:0'` — section 0 errors (empty title, empty section, weight)
/// - `'section:0:sub:1'` — sub-section 1 inside section 0
/// - `'criterion:0:2'` — criterion 2 inside section 0
/// - `'criterion:0:sub:1:0'` — criterion 0 inside sub-section 1 of section 0
/// - `'density'` — density sum error
class ValidationErrors {
  final Map<String, List<String>> _errors = {};

  void add(String key, String message) {
    _errors.putIfAbsent(key, () => []).add(message);
  }

  List<String> forKey(String key) => _errors[key] ?? const [];
  bool hasError(String key) => _errors.containsKey(key);
  bool get hasAny => _errors.isNotEmpty;
  int get totalCount =>
      _errors.values.fold(0, (sum, list) => sum + list.length);
  String? get firstKey => _errors.keys.firstOrNull;
  void clear() => _errors.clear();
}
