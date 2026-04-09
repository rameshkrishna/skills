import 'analysis_severity.dart';
import 'skill_context.dart';
import 'validation_error.dart';

/// Abstract base class for all skill validation rules.
abstract class SkillRule {
  /// The unique name of the rule (e.g., 'check-relative-paths').
  /// Used in configuration and flags.
  String get name;

  AnalysisSeverity get severity;

  /// Validates the skill provided in [context].
  Future<List<ValidationError>> validate(SkillContext context);
}
