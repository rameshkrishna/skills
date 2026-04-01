# Technical Specification: Lint Ignore System for `dart_skills_lint`

## Overview
This document specifies the implementation of a suppression system for the `dart_skills_lint` tool. The goal is to allow developers to acknowledge and "ignore" known issues in legacy Markdown files while enforcing strict checks on new content using a hierarchical configuration model.

## 1. Data Model & File Structures

The system uses a **Hybrid Configuration** approach: human-managed intent and overrides in YAML, and machine-optimized suppression records in JSON.

### A. Central Configuration (`dart_skills_lint.yaml`)
This file defines the tool's behavior, global rule severities, and the specific directories to analyze.

**Schema Requirements:**
- **`dart_skills_lint`**: Root object.
- **`rules`**: (Global) A map of rule IDs to severity levels (`error`, `warning`, `info`, `none`).
- **`directories`**: A list of directory configurations.
    - **`path`**: Root-relative path to the directory.
    - **`rules`**: (Local Override) Rule IDs and severities for this directory only.
    - **`ignore_file`**: (Local Override) Path to the JSON ignore record for this directory. Defaults to `dart_skills_lint_ignore.json` at the root of the directory path if not specified.

**Example:**
```yaml
dart_skills_lint:
  # Global Defaults
  rules:
    description_too_long: error
    invalid_skill_name: error
    path_does_not_exist: warning

  directories:
    # Use global rules, default ignore file (./lib/skills/dart_skills_lint_ignore.json)
    - path: "lib/skills/"

    # Override: Stricter rules for production directory
    - path: "prod/skills/"
      rules:
        path_does_not_exist: error
      ignore_file: "configs/prod_ignores.json"

    # Override: Relaxed rules for experimental directory
    - path: "experimental/skills/"
      rules:
        invalid_skill_name: warning
      ignore_file: "experimental/skills/suppressions.json"
```

### B. Structured Ignore Store (`dart_skills_lint_ignore.json`)
This file contains specific suppressions for all skills inside a directory context. It is located at the root of the directory containing skills.

**Schema Requirements:**
- **`version`**: String (e.g., `"0.1.0"` like in the pubspec.yaml).
- **`ignores`**: A flat list of `IgnoreEntry` objects.
- **IgnoreEntry Object:**
    - `rule_id`: String (e.g., `description_too_long`).
    - `file_name`: String (e.g., `skill-folder/SKILL.md`).

**Example:**
```json
{
  "version": "0.1.0",
  "ignores": [
    {
      "rule_id": "invalid_skill_name",
      "file_name": "v1_deprecated/SKILL.md"
    },
    {
      "rule_id": "description_too_long",
      "file_name": "v1_deprecated/SKILL.md"
    }
  ]
}
```

---

## 2. Rule Definitions (Initial Set)
The implementation must support the following Rule IDs. These must be defined in a centralized location within the codebase.

1.  **`description_too_long`** (Error): Triggered when the `description` field in Markdown frontmatter exceeds the character limit.
2.  **`invalid_skill_name`** (Error): Triggered when the `name` field contains characters outside the allowed set (e.g., `@`, `#`, `!`).
3.  **`path_does_not_exist`** (Warning): Triggered when a relative file path referenced in the Markdown does not exist on disk.

---

## 3. Implementation Logic (Workflow)

### Step 1: Initialization & Resolution
1.  Load `dart_skills_lint.yaml`.
2.  Identify all files within the specified `directories`.
3.  For each file, determine the **Most Specific Directory Config**:
    - Match the file's path against the directory `path` fields.
    - Inherit rules from the global `rules` block.
    - Apply overrides from the directory-specific `rules` block.
    - Resolve the `ignore_file` path (defaulting to the directory's root path). It is read once at the beginning of the run for the skills root.

### Step 2: The Analysis Loop
1.  Analyze each file using its resolved rule set.
2.  For every issue found:
    - Check the resolved `ignore_file` for a matching `rule_id` and `file_name`.
    - **If Match Found:** Suppress the output (do not count as a failure).
    - **If No Match:** Report the Error/Warning based on the resolved severity.

### Step 3: Stale Ignore Detection
At the end of the run, any ignore entries that were **not** used (i.e., the error is no longer present) should be reported as `INFO` notifications to encourage cleanup.

---

## 4. CLI Requirements
The CLI should support:
- `--generate-baseline`: Automatically writes all *current* issues into the appropriate JSON files based on the directory configuration.
- `--ignore-file <path>`: Global override for the suppression file (rarely used).

## 5. Success Criteria
- [ ] Linter correctly inherits global rules and applies directory overrides.
- [ ] Each directory can maintain its own independent suppression list.
- [ ] The tool exits with a non-zero code only for unsuppressed errors.
- [ ] Stale ignores are reported to help manage technical debt.
