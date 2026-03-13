import 'package:flutter/material.dart';

/// Placeholder — System Logs (admin only).
/// Full implementation in Slice 4.
class SystemLogsPage extends StatelessWidget {
  const SystemLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'System Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Coming in the next update',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
