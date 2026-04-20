import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final List<Widget> children;
  const InfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}
