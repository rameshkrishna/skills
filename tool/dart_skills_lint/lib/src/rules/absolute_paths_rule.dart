import 'dart:io';
import 'package:path/path.dart';
import '../fixable_rule.dart';
import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';

/// Enforces that links in SKILL.md do not use absolute paths.
class AbsolutePathsRule extends SkillRule implements FixableRule {
  AbsolutePathsRule({this.severity = defaultSeverity});

  static const String ruleName = 'check-absolute-paths';
  static const AnalysisSeverity defaultSeverity = AnalysisSeverity.warning;

  @override
  String get name => ruleName;

  @override
  final AnalysisSeverity severity;

  static final _markdownLinkRegex = RegExp(r'\[.*?\]\((.*?)\)');
  static const String _skillFileName = SkillContext.skillFileName;

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];

    // Extract content after YAML frontmatter
    final skillStartRegex = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true);
    final RegExpMatch? match = skillStartRegex.firstMatch(context.rawContent);
    final String markdownContent =
        match != null ? context.rawContent.substring(match.end) : context.rawContent;

    for (final RegExpMatch linkMatch in _markdownLinkRegex.allMatches(markdownContent)) {
      final String path = linkMatch.group(1)!;
      if (isAbsolute(path) || windows.isAbsolute(path)) {
        errors.add(ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Absolute filepath found in link: $path',
        ));
      }
    }

    return errors;
  }

  @override
  Future<String> fix(String filePath, String currentContent, Directory directory) async {
    if (filePath != SkillContext.skillFileName) {
      return currentContent;
    }

    final linkRegex = RegExp(r'\[.*?\]\((.*?)\)');
    var updatedContent = currentContent;

    for (final RegExpMatch match in linkRegex.allMatches(currentContent)) {
      final String path = match.group(1)!;
      if (isAbsolute(path) || windows.isAbsolute(path)) {
        final file = File(path);
        if (file.existsSync()) {
          final String relativePath = relative(path, from: directory.path);
          updatedContent = updatedContent.replaceAll('($path)', '($relativePath)');
        }
      }
    }

    return updatedContent;
  }
}
