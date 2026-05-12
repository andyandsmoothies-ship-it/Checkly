import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/constants/capability_dictionary.dart';
import '../../auth/manager/auth_manager.dart';

class ProfileCapabilitiesSection extends StatelessWidget {
  const ProfileCapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authManager = GetIt.instance<AuthManager>();
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: authManager.capabilities,
      builder: (context, capabilities, child) {
        if (capabilities.isEmpty) {
          return ExpansionTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('My Capabilities'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No capabilities assigned.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          );
        }

        final sortedCaps = capabilities.toList()..sort();

        final groups = <String, List<String>>{};
        for (final cap in sortedCaps) {
          final groupName = CapabilityDictionary.getGroup(cap);
          groups.putIfAbsent(groupName, () => []).add(cap);
        }
        final sortedGroups = groups.keys.toList()..sort();

        return ExpansionTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('My Capabilities'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedGroups.map((group) {
                    final groupCaps = groups[group]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: groupCaps
                                .map((cap) => _buildChip(cap, colorScheme))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChip(String capability, ColorScheme colorScheme) {
    return Chip(
      label: Text(CapabilityDictionary.getLabel(capability)),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide.none,
    );
  }
}
