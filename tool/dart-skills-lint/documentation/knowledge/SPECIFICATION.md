# Agent Skills Specification

This document defines the technical requirements and architectural priorities for implementing Agent Skills. It serves as a self-contained reference for engineers building or integrating skills into AI agent environments.

## 1. Overview
An **Agent Skill** is a portable, self-contained directory that extends an AI agent's capabilities. It provides the agent with specific instructions, tools, and domain-specific knowledge required to perform a specialized task.

## 2. Directory Structure
A skill directory must follow a flat and predictable structure. The only mandatory file is `SKILL.md` at the root.

```text
skill-name/
├── SKILL.md       # Required: Metadata + Instructions
├── scripts/       # Optional: Executable code (Python, Bash, JS, etc.)
├── references/    # Optional: Deep-dive documentation and templates
└── assets/        # Optional: Static resources (images, schemas, etc.)
```

## 3. The `SKILL.md` File
The `SKILL.md` file uses YAML frontmatter for machine-readable metadata, followed by Markdown-formatted instructions for the agent.

### 3.1 Metadata (YAML Frontmatter)
| Field | Required | Constraints |
| :--- | :--- | :--- |
| `name` | Yes | 1-64 chars; lowercase alphanumeric and hyphens (`-`) only; no leading/trailing/consecutive hyphens. **Must match the parent directory name.** |
| `description` | Yes | 1-1024 chars. A concise summary used by agents to determine when to activate the skill. |
| `license` | No | Short name (e.g., MIT, Apache-2.0) or reference to a bundled license file. |
| `compatibility` | No | 1-500 chars; specifies environment requirements (e.g., `Requires Python 3.10+`, `Node.js 18`). |
| `metadata` | No | Arbitrary key-value mapping for client-specific properties (e.g., `version`, `author`). |
| `allowed-tools` | No | (Experimental) Space-delimited list of pre-approved tools (e.g., `Bash(git:*)`). |

### 3.2 Instructions (Markdown Body)
The body should contain the "expert knowledge" for the agent.
- **Tone:** Direct, technical, and procedural.
- **Content:** Step-by-step workflows, input/output expectations, and edge case handling.
- **Referencing:** Use relative paths to files within the skill directory (e.g., `[See technical details](references/DETAILS.md)`).

## 4. Architectural Priorities
Implementation must adhere to these three core phases to ensure context efficiency:

### 4.1 Discovery Phase (Passive)
- **Goal:** Help the agent select the right skill without overwhelming its context window.
- **Requirement:** Only the `name` and `description` (approx. 100 tokens) should be exposed to the agent initially.

### 4.2 Activation Phase (Active)
- **Goal:** Provide the agent with the necessary instructions to perform the task.
- **Requirement:** The full content of `SKILL.md` is loaded into the agent's context once the skill is explicitly activated.
- **Constraint:** Keep `SKILL.md` under **5,000 tokens** (approx. 500 lines). Move exhaustive details to the `references/` directory.

### 4.3 Execution Phase (On-Demand)
- **Goal:** Provide deep-dive data or executable logic only when needed.
- **Requirement:** Supplemental files in `scripts/`, `references/`, or `assets/` are only read by the agent if the instructions in `SKILL.md` direct it to do so.

## 5. Implementation Requirements

### 5.1 Validation
Validation ensures that a skill directory and its `SKILL.md` file adhere to the specification. A linter or validator must check the following rules:

#### 5.1.1 Directory and File Structure
- **Existence**: The target path must exist and be a directory.
- **Mandatory File**: The root directory must contain a `SKILL.md` file.

#### 5.1.2 Metadata (YAML Frontmatter)
- **YAML Integrity**: The frontmatter must be valid YAML.
- **Allowed Fields**: Only the following fields are allowed: `name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`.
- **Required Fields**: `name` and `description` are mandatory.

#### 5.1.3 Field Specific Constraints
- **Skill Name (`name`)**:
  - Must be lowercase.
  - Length: Maximum 64 characters.
  - Characters: Only lowercase letters, digits, and hyphens (`-`).
  - No leading or trailing hyphens.
  - No consecutive hyphens (`--`).
  - **Directory Name Match**: The skill `name` must exactly match the name of its parent directory.
- **Description (`description`)**:
  - Length: Maximum 1024 characters.
- **Compatibility (`compatibility`)**:
  - Length: Maximum 500 characters.

### 5.2 Scripts & Tools
- Scripts in the `scripts/` directory should be self-documenting and provide clear error messages.

### 5.3 Versioning
- Use the `metadata` field in `SKILL.md` to track versions:
  ```yaml
  metadata:
    version: "1.0.0"
  ```

## 6. Best Practices
- **Atomic Skills:** Each skill should focus on a single, well-defined domain (e.g., "flutter-theming" instead of "general-flutter").
- **Avoid Deep Nesting:** Keep the directory structure as flat as possible. References should ideally be only one level deep from the root.
