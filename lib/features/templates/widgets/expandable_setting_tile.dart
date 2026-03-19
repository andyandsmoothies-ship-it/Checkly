import 'package:flutter/material.dart';

/// A setting row with title + switch, and a hidden description that
/// expands on tap. Implements the "Pro Interface" accordion pattern.
class ExpandableSettingTile extends StatefulWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ExpandableSettingTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    this.onChanged,
  });

  @override
  State<ExpandableSettingTile> createState() => _ExpandableSettingTileState();
}

class _ExpandableSettingTileState extends State<ExpandableSettingTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collapsed row: title + chevron + switch ──
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Title + chevron
                Expanded(
                  child: Row(
                    children: [
                      Text(widget.title, style: theme.textTheme.bodyLarge),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch (always accessible)
                Switch(value: widget.value, onChanged: widget.onChanged),
              ],
            ),
          ),
        ),

        // ── Expanded description ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 48, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
