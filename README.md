# test

## AI Workflow Script

This repository includes `ai_workflow.sh` which orchestrates a multi-stage documentation workflow using the `qwen_cli` and `openhands_cli` agents.

### Usage

```bash
./ai_workflow.sh "Describe the task here"
```

The script generates Markdown documents for each stage in the `workflow/` directory. For every stage, `openhands_cli` acts as the performer and both agents review the output twice in alternating order, starting with `qwen_cli`.

