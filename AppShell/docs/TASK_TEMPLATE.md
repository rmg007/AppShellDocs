# TASK_TEMPLATE.md

## Task Execution Template

**Purpose**: This template ensures atomic, verifiable task execution for AI agents. Fill it out before starting any work.

### Scope
- **What**: [Brief description of the task]
- **Why**: [Business/technical justification]
- **Phase**: [Which phase this belongs to, e.g., Phase 1]
- **Prerequisites**: [What must be done before this task]
- **Dependencies**: [Files/libs/tools required]

### Allowed Changes
- **Files to Edit**: [List exact files, e.g., AppShell/docs/SCHEMA.md lines 100-200]
- **Files to Create**: [New files to add]
- **Boundaries**: [What NOT to change, e.g., no new libraries, no schema changes outside X]

### Acceptance Criteria
- [ ] [Specific, measurable outcome 1]
- [ ] [Specific, measurable outcome 2]
- [ ] Validation passes: [Command to run, e.g., make validate_phase_1]
- [ ] No regressions: [How to verify, e.g., existing tests still pass]

### Validation Commands
- Primary: [e.g., make ci]
- Additional: [e.g., make db_verify_rls]

### Stop Conditions
- If [condition], STOP and ask: [e.g., If schema conflicts with AGENTS.md]
- If [condition], STOP and ask: [e.g., If unclear business rule]

### Open Questions
- [Question 1]: [Context/why needed]
- [Question 2]: [Context/why needed]

### Files to Touch (Checklist)
- [ ] [File 1] - [What to do]
- [ ] [File 2] - [What to do]

**Agent Signature**: [Date + Agent ID]