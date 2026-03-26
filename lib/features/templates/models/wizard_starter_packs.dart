/// Starter pack data for the Template Creation Wizard.
///
/// Each pack provides pre-built section + criteria structures per blueprint
/// mode. Content is intentionally generic — admins should rename to match
/// their industry terminology.
library;

// ── Data classes ──────────────────────────────────────────────────────────────

class StarterSection {
  String title;
  String description;
  final List<StarterCriterion> criteria;
  bool enabled;

  StarterSection({
    required this.title,
    this.description = '',
    required this.criteria,
    this.enabled = true,
  });
}

class StarterCriterion {
  final String label;
  final String inputType;
  final String points;

  const StarterCriterion({
    required this.label,
    required this.inputType,
    this.points = '10',
  });
}

// ── Packs ─────────────────────────────────────────────────────────────────────

class WizardStarterPacks {
  WizardStarterPacks._();

  /// Returns a fresh list of [StarterSection]s for the given scoring [mode].
  /// Callers receive mutable copies — safe to toggle `enabled` without
  /// affecting the static definitions.
  static List<StarterSection> forMode(String mode) {
    return switch (mode) {
      'penalty' => _penalty(),
      'accumulation' => _accumulation(),
      'survey' => _survey(),
      'checklist' => _checklist(),
      _ => _penalty(),
    };
  }

  // ── Penalty (Compliance Audit) ──

  static List<StarterSection> _penalty() => [
    StarterSection(
      title: 'Hygiene & Sanitation',
      criteria: [
        const StarterCriterion(label: 'Handwashing station available & stocked', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Floor and surfaces are clean', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Waste disposal is compliant', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Pest control evidence present', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Personal protective equipment worn', inputType: 'pass_fail'),
      ],
    ),
    StarterSection(
      title: 'Equipment Condition',
      criteria: [
        const StarterCriterion(label: 'Equipment is clean and functional', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Temperature logs up to date', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Safety labels intact', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Maintenance schedule followed', inputType: 'pass_fail'),
      ],
    ),
    StarterSection(
      title: 'Staff Compliance',
      criteria: [
        const StarterCriterion(label: 'Uniform and grooming standards met', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Staff trained on current procedures', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Attendance and punctuality compliant', inputType: 'pass_fail'),
      ],
    ),
    StarterSection(
      title: 'Documentation',
      criteria: [
        const StarterCriterion(label: 'Inspection records are current', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Certificates and permits displayed', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Incident log maintained', inputType: 'pass_fail'),
      ],
    ),
  ];

  // ── Accumulation (Training Assessment) ──

  static List<StarterSection> _accumulation() => [
    StarterSection(
      title: 'Knowledge Check',
      criteria: [
        const StarterCriterion(label: 'Understands key procedures', inputType: 'scale', points: '20'),
        const StarterCriterion(label: 'Can explain safety rules', inputType: 'scale', points: '20'),
        const StarterCriterion(label: 'Familiar with tools and equipment', inputType: 'scale', points: '20'),
        const StarterCriterion(label: 'Completes required reading', inputType: 'pass_fail', points: '15'),
      ],
    ),
    StarterSection(
      title: 'Practical Skills',
      criteria: [
        const StarterCriterion(label: 'Demonstrates correct technique', inputType: 'scale', points: '20'),
        const StarterCriterion(label: 'Works efficiently under supervision', inputType: 'scale', points: '15'),
        const StarterCriterion(label: 'Handles equipment safely', inputType: 'pass_fail', points: '20'),
        const StarterCriterion(label: 'Produces acceptable quality output', inputType: 'numeric', points: '15'),
      ],
    ),
    StarterSection(
      title: 'Safety Awareness',
      criteria: [
        const StarterCriterion(label: 'Identifies hazards correctly', inputType: 'scale', points: '20'),
        const StarterCriterion(label: 'Responds to emergencies appropriately', inputType: 'pass_fail', points: '25'),
        const StarterCriterion(label: 'Uses PPE consistently', inputType: 'pass_fail', points: '15'),
      ],
    ),
  ];

  // ── Survey (Feedback) ──

  static List<StarterSection> _survey() => [
    StarterSection(
      title: 'Service Quality',
      criteria: [
        const StarterCriterion(label: 'Staff were helpful and courteous', inputType: 'single_choice'),
        const StarterCriterion(label: 'Service was delivered on time', inputType: 'single_choice'),
        const StarterCriterion(label: 'Issue was resolved satisfactorily', inputType: 'single_choice'),
      ],
    ),
    StarterSection(
      title: 'Environment',
      criteria: [
        const StarterCriterion(label: 'Cleanliness of area', inputType: 'single_choice'),
        const StarterCriterion(label: 'Comfort and accessibility', inputType: 'single_choice'),
        const StarterCriterion(label: 'Noise level was acceptable', inputType: 'single_choice'),
      ],
    ),
    StarterSection(
      title: 'Overall Satisfaction',
      criteria: [
        const StarterCriterion(label: 'Overall experience rating', inputType: 'single_choice'),
        const StarterCriterion(label: 'Would you recommend us?', inputType: 'single_choice'),
      ],
    ),
  ];

  // ── Checklist ──

  static List<StarterSection> _checklist() => [
    StarterSection(
      title: 'Opening Tasks',
      criteria: [
        const StarterCriterion(label: 'Unlock and secure premises', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Power on equipment', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Check inventory levels', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Prepare workstations', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Brief team on daily objectives', inputType: 'pass_fail'),
      ],
    ),
    StarterSection(
      title: 'Closing Tasks',
      criteria: [
        const StarterCriterion(label: 'Clean and sanitize all surfaces', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Secure cash and valuables', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Power off all equipment', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Lock all entry points', inputType: 'pass_fail'),
        const StarterCriterion(label: 'Complete end-of-day report', inputType: 'pass_fail'),
      ],
    ),
  ];
}
