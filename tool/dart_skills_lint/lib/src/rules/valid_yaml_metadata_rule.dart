import 'package:yaml/yaml.dart';
import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';

/// Enforces that SKILL.md has valid YAML frontmatter and required fields.
class ValidYamlMetadataRule extends SkillRule {
  ValidYamlMetadataRule({this.severity = AnalysisSeverity.error});

  @override
  final String name = 'valid-yaml-metadata';

  @override
  final AnalysisSeverity severity;

  static const _requiredFields = {'name', 'description'};
  static const _skillFileName = 'SKILL.md';
  static const _metadataUrl = 'https://github.com/flutter/skills#metadata';

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];

    if (context.parsedYaml == null) {
      errors.add(ValidationError(
        ruleId: name,
        severity: severity,
        file: _skillFileName,
        message: context.yamlParsingError ?? 'Missing or invalid YAML metadata (see $_metadataUrl)',
      ));
      return errors;
    }

    final YamlMap yaml = context.parsedYaml!;
    for (final String field in _requiredFields) {
      if (!yaml.containsKey(field)) {
        errors.add(ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Missing required field: $field (see $_metadataUrl)',
        ));
      }
    }

    return errors;
  }
}
