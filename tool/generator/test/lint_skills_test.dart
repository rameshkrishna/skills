// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:test/test.dart';

void main() {
  test('Run skills linter', () async {
    expect(
      await validateSkills(
        skillDirPaths: ['../../skills'],
        resolvedRules: {
          'check-relative-paths': AnalysisSeverity.error,
          'check-absolute-paths': AnalysisSeverity.error,
        },
      ),
      isTrue,
    );
  });
}
