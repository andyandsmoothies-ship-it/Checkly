import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../services/admin_api_service.dart';

/// Renders a sheet allowing users to filter stores by manager name.
void showStoreManagerFilterSheet({
  required BuildContext context,
  required String? currentManagerName,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _ManagerFilterSheetBody(
        currentManagerName: currentManagerName,
        onSelected: onSelected,
      );
    },
  );
}

class _ManagerFilterSheetBody extends StatefulWidget {
  final String? currentManagerName;
  final ValueChanged<String?> onSelected;

  const _ManagerFilterSheetBody({
    required this.currentManagerName,
    required this.onSelected,
  });

  @override
  State<_ManagerFilterSheetBody> createState() => _ManagerFilterSheetBodyState();
}

class _ManagerFilterSheetBodyState extends State<_ManagerFilterSheetBody> {
  final _adminApi = GetIt.instance<AdminApiService>();
  List<String> _managers = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _adminApi.getUsers(role: 'store_manager', pageSize: 100),
        _adminApi.getUsers(role: 'area_manager', pageSize: 100),
      ]);
      final allUsers = [...results[0], ...results[1]];
      final uniqueNames = allUsers
          .map((u) => u['fullName'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      uniqueNames.sort();

      if (mounted) {
        setState(() {
          _managers = uniqueNames;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredManagers = _managers
        .where((name) => name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return SafeArea(
      key: const Key('store_manager_filter_sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Manager',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.eel,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_isLoading && _error == null && _managers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: AppColors.eel,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search managers...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppColors.wolf,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.wolf, size: 20),
                    filled: true,
                    fillColor: AppColors.swan.withValues(alpha: 0.2),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.featherGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load managers',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        color: AppColors.eel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildOption(
                      label: 'All Managers',
                      value: null,
                      isSelected: widget.currentManagerName == null,
                    ),
                    ...filteredManagers.map((mgr) => _buildOption(
                          label: mgr,
                          value: mgr,
                          isSelected: widget.currentManagerName == mgr,
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required String? value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        widget.onSelected(value);
        Navigator.maybePop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.featherGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.featherGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.featherGreen : AppColors.eel,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.featherGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
