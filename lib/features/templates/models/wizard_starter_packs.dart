/// Starter pack data for the Template Creation Wizard.
/// Provides smart suggestions for section names and criteria based on mode.
library;

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

class WizardSuggestions {
  WizardSuggestions._();

  static List<String> getSectionSuggestions(String mode) {
    return switch (mode) {
      'penalty' => ['Hygiene & Sanitation', 'Equipment Condition', 'Staff Compliance', 'Documentation'],
      'accumulation' => ['Knowledge Check', 'Practical Skills', 'Safety Awareness'],
      'survey' => ['Service Quality', 'Environment', 'Overall Satisfaction'],
      'checklist' => ['Opening Tasks', 'Closing Tasks', 'Daily Operations'],
      _ => ['General Assessment', 'Safety Checks'],
    };
  }

  static List<StarterCriterion> getCriteriaSuggestions(String mode, String sectionTitle) {
    final lowerTitle = sectionTitle.toLowerCase();
    
    // Checklist Mode Context
    if (mode == 'checklist') {
      if (lowerTitle.contains('open')) {
        return const [
          StarterCriterion(label: 'Unlock and secure premises', inputType: 'pass_fail'),
          StarterCriterion(label: 'Power on equipment', inputType: 'pass_fail'),
          StarterCriterion(label: 'Check inventory levels', inputType: 'pass_fail'),
          StarterCriterion(label: 'Prepare workstations', inputType: 'pass_fail'),
          StarterCriterion(label: 'Brief team on objectives', inputType: 'pass_fail'),
        ];
      }
      if (lowerTitle.contains('clos')) {
        return const [
          StarterCriterion(label: 'Clean and sanitize surfaces', inputType: 'pass_fail'),
          StarterCriterion(label: 'Secure cash and valuables', inputType: 'pass_fail'),
          StarterCriterion(label: 'Power off equipment', inputType: 'pass_fail'),
          StarterCriterion(label: 'Lock all entry points', inputType: 'pass_fail'),
          StarterCriterion(label: 'Complete end-of-day report', inputType: 'pass_fail'),
        ];
      }
      return const [
        StarterCriterion(label: 'Perform visual inspection', inputType: 'pass_fail'),
        StarterCriterion(label: 'Verify safety compliance', inputType: 'pass_fail'),
        StarterCriterion(label: 'Log temperature readings', inputType: 'numeric'),
      ];
    }
    
    // Penalty Mode Context
    if (mode == 'penalty') {
      if (lowerTitle.contains('hygiene') || lowerTitle.contains('sanit')) {
        return const [
          StarterCriterion(label: 'Handwashing station available', inputType: 'pass_fail'),
          StarterCriterion(label: 'Floor and surfaces clean', inputType: 'pass_fail'),
          StarterCriterion(label: 'Waste disposal is compliant', inputType: 'pass_fail'),
          StarterCriterion(label: 'Pest control evidence', inputType: 'pass_fail'),
          StarterCriterion(label: 'PPE worn correctly', inputType: 'pass_fail'),
        ];
      }
      if (lowerTitle.contains('equip')) {
        return const [
          StarterCriterion(label: 'Equipment clean & functional', inputType: 'pass_fail'),
          StarterCriterion(label: 'Temperature logs updated', inputType: 'pass_fail'),
          StarterCriterion(label: 'Safety labels intact', inputType: 'pass_fail'),
          StarterCriterion(label: 'Maintenance schedule met', inputType: 'pass_fail'),
        ];
      }
      if (lowerTitle.contains('staff') || lowerTitle.contains('compliance')) {
         return const [
          StarterCriterion(label: 'Uniform standards met', inputType: 'pass_fail'),
          StarterCriterion(label: 'Staff trained on procedures', inputType: 'pass_fail'),
          StarterCriterion(label: 'Attendance compliant', inputType: 'pass_fail'),
        ];
      }
      return const [
        StarterCriterion(label: 'SOPs followed', inputType: 'pass_fail'),
        StarterCriterion(label: 'Area free of hazards', inputType: 'pass_fail'),
      ];
    }

    // Accumulation Mode Context
    if (mode == 'accumulation') {
      if (lowerTitle.contains('knowledge')) {
        return const [
          StarterCriterion(label: 'Understands key procedures', inputType: 'scale', points: '20'),
          StarterCriterion(label: 'Can explain safety rules', inputType: 'scale', points: '20'),
          StarterCriterion(label: 'Familiar with equipment', inputType: 'scale', points: '20'),
        ];
      }
      if (lowerTitle.contains('skill') || lowerTitle.contains('practical')) {
        return const [
          StarterCriterion(label: 'Demonstrates correct technique', inputType: 'scale', points: '20'),
          StarterCriterion(label: 'Handles equipment safely', inputType: 'pass_fail', points: '20'),
          StarterCriterion(label: 'Produces acceptable quality', inputType: 'scale', points: '15'),
        ];
      }
      return const [
        StarterCriterion(label: 'Performs task to standard', inputType: 'scale', points: '10'),
      ];
    }

    // Survey Mode Context
    if (mode == 'survey') {
      if (lowerTitle.contains('service') || lowerTitle.contains('quality')) {
        return const [
          StarterCriterion(label: 'Helpful and courteous', inputType: 'single_choice'),
          StarterCriterion(label: 'Service delivered on time', inputType: 'single_choice'),
          StarterCriterion(label: 'Issue resolved satisfactorily', inputType: 'single_choice'),
        ];
      }
      if (lowerTitle.contains('environment') || lowerTitle.contains('facility')) {
         return const [
          StarterCriterion(label: 'Cleanliness of area', inputType: 'single_choice'),
          StarterCriterion(label: 'Comfort and accessibility', inputType: 'single_choice'),
          StarterCriterion(label: 'Noise level acceptable', inputType: 'single_choice'),
        ];
      }
      return const [
        StarterCriterion(label: 'Overall satisfaction', inputType: 'single_choice'),
        StarterCriterion(label: 'Would recommend us', inputType: 'single_choice'),
      ];
    }

    // Fallback
    return const [
      StarterCriterion(label: 'Standard compliance check', inputType: 'pass_fail'),
    ];
  }
}
