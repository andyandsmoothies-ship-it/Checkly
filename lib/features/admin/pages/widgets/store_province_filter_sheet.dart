import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../stores/services/store_api_service.dart';

/// Renders a sheet allowing users to filter stores by province.
void showStoreProvinceFilterSheet({
  required BuildContext context,
  required String? currentProvince,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _ProvinceFilterSheetBody(
        currentProvince: currentProvince,
        onSelected: onSelected,
      );
    },
  );
}

class _ProvinceFilterSheetBody extends StatefulWidget {
  final String? currentProvince;
  final ValueChanged<String?> onSelected;

  const _ProvinceFilterSheetBody({
    required this.currentProvince,
    required this.onSelected,
  });

  @override
  State<_ProvinceFilterSheetBody> createState() => _ProvinceFilterSheetBodyState();
}

class _ProvinceFilterSheetBodyState extends State<_ProvinceFilterSheetBody> {
  final _storeApi = GetIt.instance<StoreApiService>();
  List<String> _provinces = [];
  bool _isLoading = true;
  String? _error;

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
      final res = await _storeApi.fetchProvinces();
      if (mounted) {
        setState(() {
          _provinces = res;
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

    return SafeArea(
      key: const Key('store_province_filter_sheet'),
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
                  'Filter by Province',
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
                      'Failed to load provinces',
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
                      label: 'All Provinces',
                      value: null,
                      isSelected: widget.currentProvince == null,
                    ),
                    ..._provinces.map((prov) => _buildOption(
                          label: prov,
                          value: prov,
                          isSelected: widget.currentProvince == prov,
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
