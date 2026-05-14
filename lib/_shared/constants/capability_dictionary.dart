import 'app_capabilities.dart';

/// Provides human-readable labels, descriptions, and groupings for raw capability strings.
class CapabilityDictionary {
  CapabilityDictionary._();

  static const _meta = {
    AppCapabilities.adminAccess: {
      'label': 'Admin Panel Access',
      'group': 'Admin',
      'description': 'Grants access to the administration panel.',
    },
    AppCapabilities.adminManageRoles: {
      'label': 'Manage Roles',
      'group': 'Admin',
      'description': 'Create and manage role capabilities.',
    },
    AppCapabilities.templatesCreate: {
      'label': 'Create Templates',
      'group': 'Templates',
      'description': 'Create new inspection templates.',
    },
    AppCapabilities.templatesUpdate: {
      'label': 'Edit Templates',
      'group': 'Templates',
      'description': 'Modify existing inspection templates.',
    },
    AppCapabilities.templatesDelete: {
      'label': 'Delete Templates',
      'group': 'Templates',
      'description': 'Delete inspection templates.',
    },
    AppCapabilities.storesWrite: {
      'label': 'Manage Stores',
      'group': 'Stores',
      'description': 'Create, edit, and manage stores.',
    },
    AppCapabilities.areasWrite: {
      'label': 'Manage Areas',
      'group': 'Areas',
      'description': 'Create, edit, and manage areas.',
    },
    AppCapabilities.usersManage: {
      'label': 'Manage Users',
      'group': 'Users',
      'description': 'Create and manage user accounts and role assignments.',
    },
    AppCapabilities.analyticsAdmin: {
      'label': 'Organization Analytics',
      'group': 'Analytics',
      'description': 'View organization-wide analytics and reports.',
    },
    AppCapabilities.analyticsArea: {
      'label': 'Area Analytics',
      'group': 'Analytics',
      'description': 'View area-level analytics and reports.',
    },
    AppCapabilities.analyticsView: {
      'label': 'View Analytics',
      'group': 'Analytics',
      'description': 'View basic analytics and reports.',
    },
    AppCapabilities.submissionsList: {
      'label': 'View Submissions',
      'group': 'Submissions',
      'description': 'List and view inspection submissions.',
    },
    AppCapabilities.submissionsCreate: {
      'label': 'Create Submissions',
      'group': 'Submissions',
      'description': 'Perform inspections and submit reports.',
    },
    AppCapabilities.submissionsReview: {
      'label': 'Review Submissions',
      'group': 'Submissions',
      'description': 'Review and score completed submissions.',
    },
    AppCapabilities.actionPlansWrite: {
      'label': 'Manage Action Plans',
      'group': 'Action Plans',
      'description': 'Create and edit corrective action plans.',
    },
    AppCapabilities.actionPlansVerify: {
      'label': 'Verify Action Plans',
      'group': 'Action Plans',
      'description': 'Verify and close completed action plans.',
    },
    AppCapabilities.programsCreate: {
      'label': 'Create Campaigns',
      'group': 'Campaigns',
      'description': 'Create new audit or compliance campaigns.',
    },
    AppCapabilities.programsList: {
      'label': 'View Campaigns',
      'group': 'Campaigns',
      'description': 'List and view available campaigns.',
    },
    AppCapabilities.programsExecute: {
      'label': 'Execute Campaigns',
      'group': 'Campaigns',
      'description': 'Execute tasks assigned within campaigns.',
    },
    AppCapabilities.programsManage: {
      'label': 'Manage Campaigns',
      'group': 'Campaigns',
      'description': 'Edit and manage campaign configurations.',
    },
    AppCapabilities.programsReview: {
      'label': 'Review Campaigns',
      'group': 'Campaigns',
      'description': 'Review campaign execution and results.',
    },
    AppCapabilities.programsAssignmentsMy: {
      'label': 'My Assignments',
      'group': 'Campaigns',
      'description': 'View personal campaign assignments.',
    },
    AppCapabilities.programsAssignmentsList: {
      'label': 'View All Assignments',
      'group': 'Campaigns',
      'description': 'View all campaign assignments across the organization.',
    },
    AppCapabilities.globalRisksManage: {
      'label': 'Manage Global Risks',
      'group': 'Global Risks',
      'description': 'Create, edit, and manage global risk library.',
    },
  };

  static String getLabel(String capability) {
    return _meta[capability]?['label'] ?? _formatRaw(capability);
  }

  static String getGroup(String capability) {
    return _meta[capability]?['group'] ?? 'Other';
  }

  static String getDescription(String capability) {
    return _meta[capability]?['description'] ??
        'Allows performing the $capability action.';
  }

  static String _formatRaw(String capability) {
    final spaced = capability.replaceAll(':', ' ').trim();
    if (spaced.isEmpty) return 'Unknown';

    return spaced
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
