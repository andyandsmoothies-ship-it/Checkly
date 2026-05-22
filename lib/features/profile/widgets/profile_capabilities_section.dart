import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/constants/capability_dictionary.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../auth/manager/auth_manager.dart';

class ProfileCapabilitiesSection extends StatelessWidget {
  const ProfileCapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authManager = GetIt.instance<AuthManager>();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: authManager.capabilities,
      builder: (context, capabilities, child) {
        if (capabilities.isEmpty) {
          return ExpansionTile(
            leading: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.featherGreen,
            ),
            title: Text(
              'My Capabilities',
              style: AppFonts.displayStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.eel,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No capabilities assigned.',
                  style: AppFonts.displayStyle(
                    fontSize: 13,
                    color: AppColors.wolf,
                  ),
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
          leading: const Icon(
            Icons.verified_user_outlined,
            color: AppColors.featherGreen,
          ),
          title: Text(
            'My Capabilities',
            style: AppFonts.displayStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.eel,
            ),
          ),
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
                            style: AppFonts.displayStyle(
                              fontSize: 11,
                              color: AppColors.wolf,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: groupCaps
                                .map((cap) => _buildChip(cap))
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

  Widget _buildChip(String capability) {
    return Chip(
      label: Text(CapabilityDictionary.getLabel(capability)),
      backgroundColor: AppColors.swan.withValues(alpha: 0.4),
      labelStyle: AppFonts.displayStyle(
        fontSize: 12,
        color: AppColors.eel,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: AppColors.swan, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
