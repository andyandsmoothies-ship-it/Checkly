// SC-4: Extracted from program_wizard_steps.dart
String formatWizardDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
