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
  local review_prompt="$4"
  local file_path="$WORKDIR/$file_name"

  # Performer generates initial document
  openhands_cli -t "$performer_prompt" > "$file_path"

  # Expert verification and adjustments loop
  local agents=("qwen_cli" "openhands_cli" "qwen_cli" "openhands_cli")
  for agent in "${agents[@]}"; do
    local content
    content=$(cat "$file_path")
    local prompt
    prompt="$review_prompt"$'\n\n'$content$'\n'
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

read -r -d '' STAGE1_REVIEW <<'EOT'
You are an expert reviewing the "Initial Task Analysis" stage. Check completeness and correctness of the analysis. Correct or clarify the data in the Markdown document and return the full updated document.
EOT

run_stage "Initial Task Analysis" "01_initial_task_analysis.md" "$STAGE1_PROMPT" "$STAGE1_REVIEW"

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

read -r -d '' STAGE2_REVIEW <<'EOT'
You are an expert reviewing the "Analysis of Existing Solutions" stage. Check the relevance and validity of the found examples. Add missing solutions or remove unnecessary ones, and return the full updated document.
EOT

run_stage "Analysis of Existing Solutions" "02_existing_solutions.md" "$STAGE2_PROMPT" "$STAGE2_REVIEW"

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

read -r -d '' STAGE3_REVIEW <<'EOT'
You are an expert reviewing the "Requirements Formalization" stage. Ensure the scenarios are complete and the formulations are accurate. Refine the Markdown document and return the full updated version.
EOT

run_stage "Requirements Formalization" "03_requirements_formalization.md" "$STAGE3_PROMPT" "$STAGE3_REVIEW"

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

read -r -d '' STAGE4_REVIEW <<'EOT'
You are an expert reviewing the "Solution Design" stage. Review architectural decisions and correct or clarify diagrams and APIs. Return the full updated Markdown document.
EOT

run_stage "Solution Design" "04_solution_design.md" "$STAGE4_PROMPT" "$STAGE4_REVIEW"

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

read -r -d '' STAGE5_REVIEW <<'EOT'
You are an expert reviewing the "Implementation" stage. Check code compliance with standards and clarify descriptions, adding important points. Return the full updated Markdown document.
EOT

run_stage "Implementation" "05_implementation.md" "$STAGE5_PROMPT" "$STAGE5_REVIEW"

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

read -r -d '' STAGE6_REVIEW <<'EOT'
You are an expert reviewing the "Logging and Observability" stage. Check the informativeness of logs and metrics and adjust levels and formats as needed. Return the full updated Markdown document.
EOT

run_stage "Logging and Observability" "06_logging_observability.md" "$STAGE6_PROMPT" "$STAGE6_REVIEW"

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

read -r -d '' STAGE7_REVIEW <<'EOT'
You are an expert reviewing the "Security and Compliance" stage. Check compliance with requirements and correct any violations. Return the full updated Markdown document.
EOT

run_stage "Security and Compliance" "07_security_compliance.md" "$STAGE7_PROMPT" "$STAGE7_REVIEW"

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

read -r -d '' STAGE8_REVIEW <<'EOT'
You are an expert reviewing the "Documentation" stage. Check the README for relevance and correct wording. Return the full updated Markdown document.
EOT

run_stage "Documentation" "08_documentation_changes.md" "$STAGE8_PROMPT" "$STAGE8_REVIEW"

echo "Workflow complete. Documents are located in $WORKDIR/"
