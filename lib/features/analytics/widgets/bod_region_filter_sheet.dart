import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/bod_analytics_manager.dart';

/// Slide-up Bottom Sheet for filtering BOD analytics by Province and District.
class BodRegionFilterSheet extends StatefulWidget {
  final BodAnalyticsManager manager;

  const BodRegionFilterSheet({super.key, required this.manager});

  @override
  State<BodRegionFilterSheet> createState() => _BodRegionFilterSheetState();
}

class _BodRegionFilterSheetState extends State<BodRegionFilterSheet> {
  String? _selectedProvince;
  String? _selectedDistrict;

  final Map<String, List<String>> _provinceDistricts = const {
    'Hanoi': ['Hoan Kiem', 'Ba Dinh', 'Dong Da'],
    'Ho Chi Minh City': ['District 1', 'District 3', 'District 5'],
    'Da Nang': ['Hai Chau', 'Thanh Khe', 'Son Tra'],
  };

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.manager.activeProvince;
    _selectedDistrict = widget.manager.activeDistrict;
  }

  void _handleApply() {
    if (_selectedProvince != null && _selectedDistrict != null) {
      widget.manager.applyFilter(_selectedProvince!, _selectedDistrict!);
    }
    Navigator.of(context).pop();
  }

  void _handleClear() {
    widget.manager.clearFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = widget.manager.isLiveMode;
    final districts = _selectedProvince != null
        ? _provinceDistricts[_selectedProvince]
        : null;

    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.swan
                    : AppColors.swan.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header Row with Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Region',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isLive
                      ? AppColors.seaSponge
                      : AppColors.swan.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLive ? AppColors.featherGreen : AppColors.wolf,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLive ? AppColors.featherGreen : AppColors.wolf,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'Live Dynamic Data' : 'Nightly Snapshot',
                      style: TextStyle(
                        color: isLive ? AppColors.eel : AppColors.wolf,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a province and district to focus the board analytics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: subTextCol,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Province Dropdown (Spacious & Vertical Stack)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Province',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedProvince,
                isExpanded: true,
                style: theme.textTheme.bodyLarge?.copyWith(color: textCol),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All Provinces',
                      style: TextStyle(color: subTextCol),
                    ),
                  ),
                  ..._provinceDistricts.keys.map((prov) {
                    return DropdownMenuItem<String?>(
                      value: prov,
                      child: Text(prov),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedProvince = val;
                    _selectedDistrict = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // District Dropdown
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'District',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedDistrict,
                isExpanded: true,
                style: theme.textTheme.bodyLarge?.copyWith(color: textCol),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All Districts',
                      style: TextStyle(color: subTextCol),
                    ),
                  ),
                  if (districts != null)
                    ...districts.map((dist) {
                      return DropdownMenuItem<String?>(
                        value: dist,
                        child: Text(dist),
                      );
                    }),
                ],
                onChanged: _selectedProvince == null
                    ? null
                    : (val) {
                        setState(() {
                          _selectedDistrict = val;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            children: [
              if (isLive ||
                  _selectedProvince != null ||
                  _selectedDistrict != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.cardinal, width: 2.0),
                      foregroundColor: AppColors.cardinal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleClear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.primarySeed,
                    foregroundColor: AppColors.snow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      (_selectedProvince != null && _selectedDistrict != null)
                          ? _handleApply
                          : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text(
                    'Apply Filter',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
