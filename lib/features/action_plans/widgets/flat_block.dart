import 'package:flutter/material.dart';

class FlatBlock extends StatelessWidget {
  final Widget child;
  const FlatBlock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant, width: 3),
        ),
      ),
      child: child,
    );
  }
}
