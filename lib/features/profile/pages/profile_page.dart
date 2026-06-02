import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../auth/manager/auth_manager.dart';
import '../../../_shared/constants/app_roles.dart';
import '../../../_shared/constants/user_persona.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_theme_notifier.dart';
import '../../../_shared/widgets/primitives/primitives.dart';
import '../widgets/sign_out_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_capabilities_section.dart';
import '../widgets/profile_workspace_section.dart';

final _di = GetIt.instance;

/// Profile page — 4-zone premium layout.
///
/// Zones (always in this order):
///   1. IDENTITY — [ProfileIdentityCard] with gradient, avatar, name, email, badge.
///   2. MY WORKSPACE — [ProfileWorkspaceSection] (hidden entirely for Auditors).
///   3. SETTINGS — Theme toggle only.
///   4. MY ACCOUNT — [ProfileCapabilitiesSection] ExpansionTile.
///   5. Sign Out + version footer.
///
/// ACTIVITY zone removed (was duplicating the bottom nav ACTIVITY/INBOX tabs — Nielsen H8).
/// Templates tile visibility is REACTIVE — driven by [AuthManager.capabilities],
/// not by [UserPersona], per PBAC rules.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = _di<AuthManager>();
    final user = auth.currentUser;

    final displayName = user?.fullName ?? user?.email ?? 'user@checkly.app';
    final email = user?.email ?? 'user@checkly.app';
    final role = user?.role ?? AppRoles.auditor;
    final persona = UserPersona.fromRole(user?.role);
    final initials = _getInitials(user?.fullName ?? email);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: auth.capabilities,
        builder: (context, caps, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              // ── Zone 1: IDENTITY ──
              ProfileIdentityCard(
                initials: initials,
                displayName: displayName,
                email: email,
                role: role,
              ),

              // ── Zone 2: MY WORKSPACE (hidden for Auditors) ──
              ProfileWorkspaceSection(persona: persona, caps: caps),

              // ── Zone 3: SETTINGS ──
              _buildSettingsZone(context),

              // ── Zone 4: MY ACCOUNT ──
              _buildMyAccountZone(context),

              const SizedBox(height: 24),

              // ── Sign Out ──
              const SignOutTile(),
              const SizedBox(height: 16),

              // ── Version footer ──
              Center(
                child: Text(
                  'Checkly v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsZone(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spiritNotifier = _di<ThemeSpiritNotifier>();

    return AnimatedBuilder(
      animation: spiritNotifier,
      builder: (context, _) {
        final spirit = spiritNotifier.value;
        final isDuolingo = spirit == ThemeSpirit.duolingo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
              child: Text(
                'SETTINGS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            StrokeCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tactile 3D Design',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDuolingo
                              ? 'Active: Playful Duolingo-style 3D aesthetics'
                              : 'Active: Flat minimalist clean aesthetics',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BubblySwitch(
                    value: isDuolingo,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      spiritNotifier.toggleSpirit();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyAccountZone(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
          child: Text(
            'MY ACCOUNT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const ProfileCapabilitiesSection(),
      ],
    );
  }

  @visibleForTesting
  String getInitials(String input) => _getInitials(input);

  static String _getInitials(String input) {
    if (input.contains('@')) {
      final local = input.split('@').first;
      return local.length >= 2
          ? local.substring(0, 2).toUpperCase()
          : local.toUpperCase();
    }

    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      final name = parts.first;
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    return '??';
  }
}
