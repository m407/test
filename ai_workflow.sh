#!/usr/bin/env bash
set -euo pipefail

# Directory to store stage outputs
WORKDIR="workflow"
mkdir -p "$WORKDIR"

# Ensure qwen_cli and openhands_cli exist
command -v qwen_cli >/dev/null 2>&1 || { echo "qwen_cli not found" >&2; exit 1; }
command -v openhands_cli >/dev/null 2>&1 || { echo "openhands_cli not found" >&2; exit 1; }

TASK_DESC=${1:-"Describe the task here"}

run_stage() {
  local stage_name="$1"
  local file_name="$2"
  local performer_prompt="$3"
  local file_path="$WORKDIR/$file_name"

  # Performer generates initial document
  openhands_cli -t "$performer_prompt" > "$file_path"

  # Expert verification and adjustments loop
  local agents=("qwen_cli" "openhands_cli" "qwen_cli" "openhands_cli")
  for agent in "${agents[@]}"; do
    local content
    content=$(cat "$file_path")
    local prompt
    prompt=$(printf 'You are an expert reviewing stage "%s". Refine the following Markdown and return the full updated document.\n\n%s\n' "$stage_name" "$content")
    "$agent" -t "$prompt" > "$file_path"
  done
}

# Stage 1: Initial Task Analysis
read -r -d '' STAGE1_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Perform the following actions:
- Determine which system components will be changed or extended.
- Clarify the context boundaries within the repository.
- Record key rules and constraints (invariants).
- Identify the events or signals that will be used.
- If necessary, align the task with the requester.
Create a Markdown document with the analysis results using the structure below:

# Initial Task Analysis

## 1. Task Description
A brief description of the task in your own words.

## 2. Affected Entities
- Entity 1 — short explanation.
- Entity 2 — short explanation.

## 3. Context Boundaries
Description of the module/context where the changes will take place.

## 4. Invariants
- Invariant 1
- Invariant 2

## 5. Events/Signals
- Event 1 — description.
- Event 2 — description.

## 6. Notes
Any additional remarks that may affect the design.
EOT

run_stage "Initial Task Analysis" "01_initial_task_analysis.md" "$STAGE1_PROMPT"

# Stage 2: Analysis of Existing Solutions
read -r -d '' STAGE2_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Find similar implementations in the repository, study architecture and conventions, identify opportunities for code reuse, and use git history if necessary. Create a Markdown document using the structure:

# Analysis of Existing Solutions

## 1. Found Analogs
| Module/File        | Functionality Description | Code/Commit Link |
|--------------------|---------------------------|------------------|
| example.py         | Short description         | [Link](...)       |

## 2. Conclusions
- Which elements can be reused.
- Which parts need modification.
- What must be implemented from scratch.

## 3. Notes
Specifics that influence the approach selection.
EOT

run_stage "Analysis of Existing Solutions" "02_existing_solutions.md" "$STAGE2_PROMPT"

# Stage 3: Requirements Formalization
read -r -d '' STAGE3_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Define acceptance criteria, positive and negative scenarios, and requirements for resilience and idempotency. Create a Markdown document using the structure:

# Requirements Formalization

## 1. Acceptance Criteria
- Criterion 1
- Criterion 2

## 2. Positive Scenarios
1. Action → expected result.
2. Action → expected result.

## 3. Negative Scenarios
1. Invalid input → error message.
2. Network failure → retry.

## 4. Resilience and Idempotency Requirements
Description of behavior on repeated requests or failures.

## 5. Notes
Additional information.
EOT

run_stage "Requirements Formalization" "03_requirements_formalization.md" "$STAGE3_PROMPT"

# Stage 4: Solution Design
read -r -d '' STAGE4_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Define the change architecture, identify events and integration points, define new entities or components, and describe APIs and data formats. Create a Markdown document using the structure:

# Solution Design

## 1. Change Architecture
Description of the planned change structure.

## 2. New Entities/Components
- Entity 1 — purpose.
- Entity 2 — purpose.

## 3. Events/Signals
- Event 1 — source and handler.
- Event 2 — source and handler.

## 4. APIs and Data Formats
- Endpoint 1 — input, output.
- Endpoint 2 — input, output.

## 5. Diagrams (if needed)
Link or embedded image.

## 6. Notes
Implementation specifics.
EOT

run_stage "Solution Design" "04_solution_design.md" "$STAGE4_PROMPT"

# Stage 5: Implementation
read -r -d '' STAGE5_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Implement changes according to the architecture while following coding standards. Create a Markdown document using the structure:

# Implementation

## 1. Modified Files
- path/to/file1 — what changed.
- path/to/file2 — what changed.

## 2. New Files
- path/to/new_file — purpose.

## 3. Key Changes
Brief description of the logic.

## 4. Specifics
Important information for working with this code.

## 5. Notes
Technical nuances depending on the environment.
EOT

run_stage "Implementation" "05_implementation.md" "$STAGE5_PROMPT"

# Stage 6: Logging and Observability
read -r -d '' STAGE6_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Add logging and metrics. Create a Markdown document using the structure:

# Logging and Observability

## 1. Added Logs
- Log insertion point → log level → description.

## 2. Metrics
- Metric name → what it measures → where it's collected.

## 3. Notes
Specifics of integration with the monitoring system.
EOT

run_stage "Logging and Observability" "06_logging_observability.md" "$STAGE6_PROMPT"

# Stage 7: Security and Compliance
read -r -d '' STAGE7_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Verify access rights and code style compliance. Create a Markdown document using the structure:

# Security and Compliance

## 1. Access Rights Check
Description of the check and results.

## 2. Code Style Compliance
Description of applied tools and check results.

## 3. Additional Security Measures
List of added checks or restrictions.

## 4. Notes
Additional information.
EOT

run_stage "Security and Compliance" "07_security_compliance.md" "$STAGE7_PROMPT"

# Stage 8: Documentation
read -r -d '' STAGE8_PROMPT <<'EOT'
You are the Performer for the following task:
$TASK_DESC

Update the README and create a Markdown document describing the changes using the structure:

# Documentation of Changes

## 1. Updated README Sections
- Section 1 — what was added/changed.
- Section 2 — what was removed.

## 2. Links
Link to README in the repository.

## 3. Notes
Documentation-related specifics.
EOT

run_stage "Documentation" "08_documentation_changes.md" "$STAGE8_PROMPT"

echo "Workflow complete. Documents are located in $WORKDIR/"
