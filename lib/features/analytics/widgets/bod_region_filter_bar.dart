import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/bod_analytics_manager.dart';

/// Region Filter Bar for filtering BOD analytics by Province and District.
class BodRegionFilterBar extends StatefulWidget {
  final BodAnalyticsManager manager;

  const BodRegionFilterBar({super.key, required this.manager});

  @override
  State<BodRegionFilterBar> createState() => _BodRegionFilterBarState();
}

class _BodRegionFilterBarState extends State<BodRegionFilterBar> {
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

  @override
  void didUpdateWidget(covariant BodRegionFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manager.activeProvince != _selectedProvince ||
        widget.manager.activeDistrict != _selectedDistrict) {
      setState(() {
        _selectedProvince = widget.manager.activeProvince;
        _selectedDistrict = widget.manager.activeDistrict;
      });
    }
  }

  void _handleApply() {
    if (_selectedProvince != null) {
      widget.manager.applyFilter(_selectedProvince!, _selectedDistrict ?? '');
    }
  }

  void _handleClear() {
    setState(() {
      _selectedProvince = null;
      _selectedDistrict = null;
    });
    widget.manager.clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = widget.manager.isLiveMode;
    final districts = _selectedProvince != null
        ? _provinceDistricts[_selectedProvince]
        : null;

    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight
        ? AppColors.snow
        : (theme.cardTheme.color ?? Colors.transparent);
    final borderCol = isLight
        ? AppColors.swan
        : AppColors.swan.withValues(
            alpha: 0.15,
          ); // withAlpha is deprecated in flutter, withValues(alpha: ...) is modern and standard

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Region',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
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
          const SizedBox(height: 12),
          Row(
            children: [
              // Province Dropdown
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Province',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedProvince,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Provinces')),
                      ..._provinceDistricts.keys.map((prov) {
                        return DropdownMenuItem<String?>(value: prov, child: Text(prov));
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
              const SizedBox(width: 12),
              // District Dropdown
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'District',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String?>(
                    value: _selectedDistrict,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Districts')),
                      if (districts != null)
                        ...districts.map((dist) {
                          return DropdownMenuItem<String?>(value: dist, child: Text(dist));
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isLive ||
                  _selectedProvince != null ||
                  _selectedDistrict != null)
                TextButton.icon(
                  onPressed: _handleClear,
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.cardinal,
                  ),
                  label: const Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: AppColors.cardinal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                onPressed:
                    _selectedProvince != null
                    ? _handleApply
                    : null,
                icon: const Icon(Icons.search_rounded),
                label: const Text(
                  'Apply Filter',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
