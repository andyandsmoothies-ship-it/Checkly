import 'package:flutter/material.dart';
import '../../../_shared/widgets/primitives/universal_store_group.dart';

class TypeSection extends StatelessWidget {
  final String label;
  final int count;
  final bool initiallyExpanded;
  final List<Widget> children;

  const TypeSection({
    super.key,
    required this.label,
    required this.count,
    this.initiallyExpanded = true,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalStoreGroup(
      storeName: label,
      count: count,
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      children: children,
    );
  }
}
