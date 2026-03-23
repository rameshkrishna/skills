---
name: "flutter-ci-cd"
description: "Designs CI/CD pipelines for Flutter apps, including pull request validation, build automation, artifact publishing, signing boundaries, and store release workflows. Use when setting up Flutter build, test, and release automation with GitHub Actions, Fastlane, or similar CI systems."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Sun, 22 Mar 2026 00:00:00 GMT"

---
# Flutter CI/CD

## Contents
- [Core Principles](#core-principles)
- [Workflow: Designing the Pipeline Shape](#workflow-designing-the-pipeline-shape)
- [Workflow: Pull Request Validation](#workflow-pull-request-validation)
- [Workflow: Release Automation](#workflow-release-automation)
- [Workflow: Adapting the Pipeline for Monorepos and Multi-App Repos](#workflow-adapting-the-pipeline-for-monorepos-and-multi-app-repos)
- [Examples](#examples)

## Core Principles
- **Separate CI from CD:** Keep pull request validation independent from release and store delivery. Fast feedback should not depend on signing credentials or manual release gates.
- **Prefer GitHub Actions by default:** Use GitHub Actions terminology and workflow structure unless the user explicitly targets another CI provider.
- **Use Fastlane for mobile release promotion:** Route store upload and release-lane logic through Fastlane rather than embedding brittle store-specific shell steps directly in the CI configuration.
- **Treat secrets and signing as external prerequisites:** Never assume certificates, keystores, API keys, or provisioning assets live in the repository. Reference them as securely injected inputs.
- **Ask about release build options before release builds:** Treat Dart obfuscation and other material release flags as explicit user decisions. Do not enable them silently.
- **Build the minimum necessary matrix:** Expand OS, Flutter channel, or app target matrices only when they materially increase confidence or support a real release requirement.

## Workflow: Designing the Pipeline Shape

Use this workflow first to choose the correct CI/CD structure before writing provider-specific configuration.

**Task Progress:**
- [ ] Identify whether the request is PR validation, release automation, or both.
- [ ] Identify target platforms: Android, iOS, web, desktop, or package-only.
- [ ] Identify whether integration tests require emulators, simulators, devices, or services.
- [ ] Identify which steps must run on every change versus only on protected branches, tags, or manual dispatch.
- [ ] Identify which secrets and signing assets are required and where they will be injected from.

**Conditional Logic:**
- **If the request is PR validation only:** Design a CI workflow that runs dependency install, formatting checks, static analysis, and relevant test suites. Exclude signing, store upload, and long-running release steps.
- **If the request includes Android release:** Add a release workflow that builds a signed `appbundle` or `apk`, stores artifacts, and invokes a Fastlane lane for distribution.
- **If the request includes iOS release:** Add a macOS-based release workflow with explicit code signing prerequisites, archive/export steps, and a Fastlane lane for TestFlight or App Store delivery.
- **If the user asks for one pipeline file for everything:** Prefer separate validation and release jobs or separate workflows unless the repo is extremely small and the operational risk is low.

## Workflow: Pull Request Validation

Use this workflow for fast, repeatable feedback on changes before merge.

**Task Progress:**
- [ ] Install Flutter and restore dependencies with `flutter pub get`.
- [ ] Run formatting checks, typically `dart format --output=none --set-exit-if-changed .`.
- [ ] Run static analysis with `flutter analyze`.
- [ ] Run unit and widget tests with `flutter test`.
- [ ] Run integration tests only when the environment can support them.
- [ ] Publish logs or test artifacts if failures are expensive to reproduce.

**Conditional Logic:**
- **If the project contains only pure Dart or package code:** Use a lighter pipeline and skip device or platform build jobs.
- **If integration tests require Linux desktop:** Run them behind `xvfb-run` or an equivalent virtual display setup.
- **If integration tests require Android or iOS devices:** Run them in a dedicated job or separate workflow so routine PR validation stays fast.
- **If build verification is needed on pull requests:** Build unsigned artifacts only. Keep signing and store upload out of PR execution paths.

## Workflow: Release Automation

Use this workflow when the user needs artifacts, internal distribution, or store submission.

**Task Progress:**
- [ ] Confirm the release trigger: branch push, tag, manual dispatch, or protected environment approval.
- [ ] Restore dependencies and rerun the minimum validation required before release.
- [ ] Confirm whether obfuscation or any other relevant release build options should be enabled for release artifacts.
- [ ] Build platform-specific artifacts using Flutter build commands.
- [ ] Inject secrets and signing materials from the CI provider's secure storage.
- [ ] Invoke Fastlane to perform distribution, metadata upload, or store submission.
- [ ] Persist artifacts and release logs for auditing and rollback support.

**Conditional Logic:**
- **If releasing Android:** Prefer `flutter build appbundle` for Play Store delivery. Use Fastlane to manage track upload and release promotion.
- **If releasing iOS:** Run on macOS, ensure signing prerequisites exist before the build starts, then use Fastlane for TestFlight or App Store Connect upload.
- **If the user has not stated which release build options should be enabled:** Ask before finalizing release commands or workflow snippets. Confirm obfuscation and any other material options such as split-debug-info handling, target flavor, target entrypoint, dart-defines, export method, or target-platform overrides when they affect the release build.
- **If the user wants obfuscation enabled:** Add `--obfuscate` and a persistent `--split-debug-info=<secure path>` output directory to the release build step. Preserve the generated symbol files as protected CI artifacts so crash symbolication remains possible.
- **If the user does not want obfuscation:** Omit `--obfuscate` and do not invent symbol-storage requirements.
- **If the user only needs build artifacts:** Stop after artifact publication and do not add store delivery lanes.
- **If secrets are not available yet:** Design the workflow with placeholders and explicit prerequisites instead of inventing insecure local-file assumptions.

## Workflow: Adapting the Pipeline for Monorepos and Multi-App Repos

Use this workflow when one repository contains multiple Flutter apps, packages, or shared modules.

**Task Progress:**
- [ ] Identify the app or package boundaries.
- [ ] Add path-based triggering or filtering so unrelated changes do not fan out across every job.
- [ ] Build a matrix only for the apps or targets that genuinely need separate execution.
- [ ] Keep shared bootstrap steps reusable across jobs.
- [ ] Publish artifacts with app-specific names to avoid collisions.

**Conditional Logic:**
- **If the repo contains shared packages plus one app:** Validate shared packages broadly, but scope release automation to the app target only.
- **If multiple Flutter apps ship independently:** Use app-specific workflows or matrices with explicit artifact naming and independent release lanes.
- **If another CI provider is required:** Preserve the same stage boundaries, secret model, and release separation while translating the job syntax from GitHub Actions into the target system.

## Examples

### Example: Pull Request Validation Only
Use this shape when the user asks for GitHub Actions CI for a Flutter repository:

```text
trigger: pull_request
jobs:
  - checkout -> setup Flutter -> cache pub deps
  - flutter pub get
  - dart format --output=none --set-exit-if-changed .
  - flutter analyze
  - flutter test
  - optional unsigned build verification
```

### Example: Android Release
Use this shape when the user asks to ship a Flutter Android app through CI/CD:

```text
trigger: tag or manual dispatch
jobs:
  - validate minimum checks
  - restore signing inputs from secrets
  - ask whether obfuscation or other relevant release build options should be enabled
  - flutter build appbundle --release [plus --obfuscate and --split-debug-info when requested]
  - fastlane android beta|deploy
  - upload AAB and logs as artifacts
```

### Example: iOS Release
Use this shape when the user asks for TestFlight or App Store delivery:

```text
trigger: protected branch or manual dispatch
runner: macos
jobs:
  - setup Flutter and CocoaPods dependencies
  - verify signing prerequisites
  - ask whether obfuscation or other relevant release build options should be enabled
  - flutter build ipa or archive/export flow [plus obfuscation flags when requested]
  - fastlane ios beta|release
  - retain archive, export logs, and release metadata
```

### Example: Monorepo Decision
If the repo contains multiple Flutter apps, prefer:

```text
- path filters to scope CI
- a matrix only across affected apps
- one shared validation workflow
- app-specific release jobs or lanes
```
