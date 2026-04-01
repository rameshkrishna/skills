import 'dart:io';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';
import 'package:path/path.dart' as p;
import 'package:dart_skills_lint/src/entry_point.dart';

void main() {
  group('Configuration File Integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('config_test.');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('obeys disabled relative paths in config', () async {
      final skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''---
name: test-skill
description: A test skill
---
[broken](missing.md)''');

      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  rules:
    check-relative-paths: disabled
''');

      final process = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'test-skill'],
        workingDirectory: tempDir.path,
      );

      final stdout = await process.stdout.rest.toList();
      expect(stdout.join('\n'), contains('Skill is valid.'));
      await process.shouldExit(0);
    });

    test('obeys warning absolute paths in config', () async {
      final skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''---
name: test-skill
description: A test skill
---
[absolute](/absolute/path.md)''');

      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  rules:
    check-absolute-paths: warning
''');

      final process = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'test-skill'],
        workingDirectory: tempDir.path,
      );

      final stdout = await process.stdout.rest.toList();
      expect(stdout.join('\n'), contains('Warnings:'));
      await process.shouldExit(0);
    });

    test('CLI flags override config', () async {
      final skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''---
name: test-skill
description: A test skill
---
[broken](missing.md)''');

      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  rules:
    check-relative-paths: disabled
''');

      final process = await TestProcess.start(
        'dart',
        [
          p.normalize(p.absolute('bin/dart_skills_lint.dart')),
          '-s',
          'test-skill',
          '--check-relative-paths'
        ],
        workingDirectory: tempDir.path,
      );

      final stdout = await process.stdout.rest.toList();
      expect(stdout.join('\n'), contains('Warnings:'));
      await process.shouldExit(0);
    });

    test('writes empty ignore-file if missing and specified in config', () async {
      await Directory('${tempDir.path}/test-skill').create();
      await File('${tempDir.path}/test-skill/SKILL.md').writeAsString('''---
name: test-skill
description: A test skill
---
Body''');

      final ignorePath = 'custom_ignore.json';
      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  directories:
    - path: "test-skill"
      ignore_file: "$ignorePath"
''');

      final process = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'test-skill'],
        workingDirectory: tempDir.path,
      );

      final stdout = await process.stdout.rest.toList();
      expect(stdout.join('\n'), contains('File not found generating-baseline'));
      await process.shouldExit(0);

      final writtenFile = File('${tempDir.path}/$ignorePath');
      expect(await writtenFile.exists(), isTrue);
      final fileContent = await writtenFile.readAsString();
      expect(fileContent, contains('"skills":'));
    });

    test('ignores config when --ignore-config is passed', () async {
      final skillDir = await Directory('${tempDir.path}/TEST-SKILL').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''---
name: TEST-SKILL
description: A test skill
license: MIT
---
Body''');

      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  rules:
    invalid-skill-name: disabled
''');

      // 1. Run without --ignore-config. Should pass because config disables the check.
      final passProcess = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'TEST-SKILL'],
        workingDirectory: tempDir.path,
      );
      await passProcess.shouldExit(0);

      // 2. Run with --ignore-config. Should fail because config is ignored and default is used.
      final failProcess = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'TEST-SKILL', '--ignore-config'],
        workingDirectory: tempDir.path,
      );
      await failProcess.shouldExit(1);
    });

    test('ignores config when generating baseline with --ignore-config', () async {
      final skillDir = await Directory('${tempDir.path}/TEST-SKILL').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''---
name: TEST-SKILL
description: A test skill
license: MIT
---
Body''');

      await File('${tempDir.path}/dart_skills_lint.yaml').writeAsString('''
dart_skills_lint:
  rules:
    invalid-skill-name: disabled
''');

      // 1. Generate baseline with --ignore-config. It should ignore config (so the rule is enabled) and find violations to generate baseline for!
      final genProcess = await TestProcess.start(
        'dart',
        [p.normalize(p.absolute('bin/dart_skills_lint.dart')), '-s', 'TEST-SKILL', '--generate-baseline', '--ignore-config'],
        workingDirectory: tempDir.path,
      );
      await genProcess.shouldExit(0); // Exits 0 if --generate-baseline passed

      final ignoreFile = File('${skillDir.path}/$defaultIgnoreFileName');
      expect(await ignoreFile.exists(), isTrue);

      final content = await ignoreFile.readAsString();
      expect(content, contains('invalid-skill-name')); // It should generate baseline for it!
    });
  });
}
