// Dart models representing template linter issues.
// Matches backend server/Features/Templates/TemplateLinter.cs

class LintIssue {
  final String ruleId;
  final String message;
  final String? targetId;
  final String severity; // 'Error' | 'Warning'

  LintIssue({
    required this.ruleId,
    required this.message,
    this.targetId,
    required this.severity,
  });

  factory LintIssue.fromJson(Map<String, dynamic> json) {
    return LintIssue(
      ruleId: json['ruleId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetId: json['targetId'] as String?,
      severity: json['severity'] as String? ?? 'Warning',
    );
  }

  Map<String, dynamic> toJson() => {
    'ruleId': ruleId,
    'message': message,
    'targetId': targetId,
    'severity': severity,
  };
}

class LintResult {
  final List<LintIssue> errors;
  final List<LintIssue> warnings;

  LintResult({required this.errors, required this.warnings});

  factory LintResult.fromJson(Map<String, dynamic> json) {
    final errorsList =
        (json['errors'] as List?)
            ?.map((e) => LintIssue.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final warningsList =
        (json['warnings'] as List?)
            ?.map((e) => LintIssue.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return LintResult(errors: errorsList, warnings: warningsList);
  }

  Map<String, dynamic> toJson() => {
    'errors': errors.map((e) => e.toJson()).toList(),
    'warnings': warnings.map((e) => e.toJson()).toList(),
  };

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
