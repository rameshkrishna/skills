# Engineering Roadmap: `dart-skills-lint`

This document translates the Production Readiness Evaluation into a set of engineering tasks for the development team.

## Objective
Enhance `dart_skills_lint` from a prototype to a production-ready, globally accessible linter for Agent Skills.

---

## 1. Distribution & Ecosystem (High Priority)
**Goal:** Enable use without a pre-existing Dart SDK.

### Tasks:
- [ ] **Native Executables:** Configure a CI/CD pipeline (e.g., GitHub Actions) to use `dart compile exe` for:
    - `linux-x64`, `macos-x64`, `macos-arm64`, `windows-x64`.
- [ ] **GitHub Action:** Create a dedicated Action (`dart-lang/skills-lint-action`) that downloads the correct binary and runs it.
- [ ] **Pub.dev Release:** Prepare the package for its initial `1.0.0` release (docs, CHANGELOG, etc.).
- [ ] **Install Script:** Provide a one-liner install script (e.g., `curl | bash`) for quick setup.

## 2. CI/CD Integration (Medium Priority)
**Goal:** Support automated reporting in enterprise environments.

### Tasks:
- [ ] **Output Formats:** 
    - Implement a `--format` flag supporting `text` (default), `json`, and `junit`.
    - Support the [SARIF](https://sarifweb.azurewebsites.net/) format for integration with GitHub Security scans.
- [ ] **STDOUT/STDERR Separation:** Ensure only actual errors go to `stderr`; all normal reporting should go to `stdout`.
- [ ] **Summary Reporting:** Add a final report summary (e.g., `Found 5 errors, 2 warnings in 10 skills.`).

## 3. Feature Enhancements (Medium Priority)
**Goal:** Improve developer experience and flexibility.

### Tasks:
- [ ] **Rule Suppression (Ignore):** 
    - Implement inline comments support (e.g., `[Link](path.md) <!-- ignore: broken-link -->`).
    - Support global ignore rules in `dart_skills_lint.yaml` for specific skills or paths.
- [ ] **Auto-Detection:**
    - Improve the "batch" mode. If no path is provided, the tool should recursively search for `SKILL.md` files starting from the root.
- [ ] **Initialization:**
    - Add `dart_skills_lint init` to generate a standard configuration file and an optional GitHub Action workflow.
- [ ] **Auto-Fix:**
    - Implement a `--fix` flag for name mismatch errors (rename the field to match the directory).

## 4. Stability & Performance (Low Priority)
**Goal:** Ensure reliability across platforms and large repositories.

### Tasks:
- [ ] **Windows Cross-Testing:** 
    - Add GitHub Actions runners for Windows.
    - Specifically test absolute path validation using `C:\` and UNC paths.
- [ ] **Async Refactor:** 
    - Audit `Validator` to ensure no blocking synchronous calls are made during directory traversal.
- [ ] **Performance Benchmarking:** 
    - Create a test case with 10,000 mock skills to identify bottlenecks.

---

## Technical Specification: JSON Output Format
The JSON output should follow this schema for easy parsing:

```json
{
  "summary": { "errors": 2, "warnings": 1, "skills_processed": 5 },
  "results": [
    {
      "skill": "my-skill-name",
      "path": "./skills/my-skill-name",
      "valid": false,
      "violations": [
        { "type": "error", "code": "name-mismatch", "message": "..." },
        { "type": "warning", "code": "broken-link", "message": "..." }
      ]
    }
  ]
}
```
