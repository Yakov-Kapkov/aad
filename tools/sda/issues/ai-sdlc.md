# AI-Driven SDLC — Ideas for Future Consideration

Ideas captured from design discussions on 2026-06-29 and 2026-06-30. Not scheduled. Return when system context is stable.

---

## What Is AI SDLC Workflow?

### Mirror the logical structure, not the mechanics

Human SDLC phases (plan → design → implement → test → ship) exist because of *logical dependencies in software*, not human preferences. Those don't change. An AI SDLC needs the same phases.

What it should NOT inherit from Human SDLC:

| Human SDLC mechanic | Why it exists | AI SDLC alternative |
|---|---|---|
| Meetings / standups | Context lives in heads — sync it | Context lives in files — agents read it |
| PR code review | Human code quality is inconsistent | Agent quality gates + contract verification |
| Ticket systems (Jira) | Work coordination across humans | Task specs + project-level state machine |
| "Done" is social consensus | No explicit terminal state | Explicit state transitions with machine-readable criteria |
| Tribal knowledge | People carry it | System context + decision records |

### The key structural difference

**Human SDLC is context-lossy by design** — people forget, leave, misremember, and the process tolerates it. **AI SDLC must be context-explicit by design** — everything an agent needs to act correctly must exist in a file it can read. This is why system context is foundational, not optional.

### What AI SDLC adds that Human SDLC lacks

An **explicit terminal state per task**. Humans consider a task "done" informally. AI SDLC requires all pipeline stages to be provably complete:

```
Backlog → Designed → Implemented → Verified → Context-Updated → Done
```

No implicit "done." Each transition has machine-readable criteria. `Context-Updated` is a first-class state, not an afterthought.

### Human checkpoints are required, not optional

AI agents make design and implementation decisions. Some of those decisions must require explicit human confirmation before the pipeline advances — especially when they contradict architectural decisions or invalidate verified behaviors. The workflow engine must support **pause + notify + resume** at defined checkpoint types.

---

## The Workflow Engine

### What it is NOT

- Not a cloud service (async gap, infrastructure coupling)
- Not GitHub Actions (fires on merge, not on agent completion; cloud-dependent)
- Not a running background monolith (fragile, session-coupled)
- Not VS Code-coupled (VS Code is an execution environment, not the engine)

### What it IS — a local CLI workflow runner

The engine is a **local CLI** that:
- Owns `project-state.json` (current pipeline state for all tracked tasks)
- Knows the pipeline rules (what stage follows what, what the transition criteria are)
- Monitors for stage completion signals (agents write completion to state files)
- Advances the pipeline when criteria are met
- Pauses at human checkpoints and notifies the user
- Does NOT do AI work — it orchestrates which agent to invoke and when

```
sda-workflow start task-012
  [pipeline advances stage by stage]
  [agents write completion to state files; CLI monitors]
  [hits human checkpoint: conflict detected in system context]

  ⛔ Paused — human decision required.
     Task: task-012 | Stage: Design | Conflict: D001 in auth domain
     See: .sda/state/task-012.json
  [OS/terminal notification]
```

### Dual interface

The user responds to a checkpoint via one of two paths:

**(a) VS Code prompt** — a `.prompt.md` reads the current state file, surfaces the checkpoint, lets the user respond in chat. VS Code is a UI layer over the CLI's state — not the engine.

**(b) TUI or localhost dashboard** — the CLI serves a terminal UI or simple web view showing pipeline state across all tasks. Fully decoupled from VS Code. User can start/resume/inspect without opening an editor.

### Coupling is one-directional

```
CLI → writes → state files ← reads ← VS Code prompts
```

Neither the CLI nor VS Code depends on the other's runtime. The CLI advances state; VS Code prompts are optional UI. As agent APIs mature (Claude Code CLI, Copilot API), the CLI can invoke agents directly without VS Code.

**Short-term**: CLI manages state + tells user what to invoke in VS Code chat.
**Medium-term**: CLI invokes lightweight agents directly via API for non-interactive stages.
**Long-term**: fully autonomous pipeline with human checkpoints as the only pauses.

### Open questions on the engine
- What language/runtime for the CLI? (PowerShell/Bash = consistent with SDA; Node.js/Python = better event handling)
- How does an agent signal completion? (Write a sentinel file? Update state.json directly? Emit a structured log?)
- What is the checkpoint notification mechanism? (OS toast, terminal bell, TUI alert?)
- How does the CLI know which agent to invoke for each stage? (Hardcoded pipeline rules? Configurable per project?)

---

## SDLC as a State Machine

Current SDA tracks state per task (`state.json`). The broader SDLC cycle is implicit.

**Idea:** define an explicit project-level state machine where a task moves through named states:

```
Backlog → Designed → Implemented → Verified → Context-Updated → Done
```

`Context-Updated` is a new terminal state that makes system context maintenance a first-class SDLC step, not an afterthought. A task is not `Done` until context reflects it.

**Open questions:**
- Where does project-level state live? A `project-state.json` at `.sda/`?
- Which agent owns state transitions?
- How do transitions trigger the correct agent automatically?

---

## Automatic Pipeline Wiring

Currently: `sda-context-writer` is invoked manually after QA.

**Future:** wire it as a mandatory pipeline stage — same way `sda-qa` was first standalone, then became a delegation target of `sda-dev`. Once context writer is stable, it becomes the automatic successor to a passed QA.

---

## External Event Triggers (GitHub / CI)

**Idea:** emit a context update trigger on PR approval or merge via a GitHub Action or git hook. This is a safeguard for workflows where work happens outside SDA (manual commits, hotfixes, external contributors).

**Concerns:**
- Adds external infrastructure coupling
- Async gap — PR can sit open for days before merge
- Agent has less context at merge time than at verification time
- Not needed if all work goes through the SDA pipeline

**Verdict (current):** not the core mechanism. Viable as an optional safety net only.

---

## Project-Level SDLC Orchestrator

If SDA evolves into a full SDLC engine, a project-level orchestrator agent could:
- Track which tasks are in which state
- Trigger the right agent at the right time (task designed → invoke sda-dev, QA passed → invoke sda-context-writer)
- Maintain the project-level state machine

This would be a new agent above `sda-dev` in the hierarchy. Currently out of scope — design only when context writer and state machine are stable.

---

## Context Writer as Setup Companion

During fresh SDA project setup, `sda-context-writer` (or a variant) could:
- Read `design.md` if it exists
- Create skeleton domain context files from architectural decisions already captured
- Initialize empty `verified_behaviors` tables

This avoids needing a separate onboarding agent for context initialization.
