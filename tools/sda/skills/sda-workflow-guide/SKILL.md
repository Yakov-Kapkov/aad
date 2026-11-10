---
name: sda-workflow-guide
description: "Workflow layer for SDA — the fixed container paths, the workflow CLI, the stage gate, finish/escalate/resolve, and the orchestrator's container housekeeping. Use when: a stage agent (sda-ba, sda-design, sda-dev) runs a workflow session, sda-workflow is orchestrating a container, or a request names a workflow container. Otherwise never load it."
---

# Workflow layer

A workflow is a numbered container (`.sda/workflows/<NNN>. <slug>/`) holding one issue's
artifacts plus script-written state (`workflow.json`). This skill is the whole workflow layer —
the CLI, the layout, the gate, and the steps of each role. Your role's specifics live in its
card:

| Role | Agent | Card |
|---|---|---|
| orchestrator | `sda-workflow` | [`assets/orchestrator.md`](assets/orchestrator.md) |
| `story` stage | `sda-ba` | [`assets/stage-story.md`](assets/stage-story.md) |
| `design` stage | `sda-design` | [`assets/stage-design.md`](assets/stage-design.md) |
| `dev` stage | implementation session | [`assets/stage-dev.md`](assets/stage-dev.md) |

Read your card first. It names your role, your artifact, your input, who you escalate to, and
when you may `advance`.

## Paths — fixed

Nothing about the workflow layer is configurable.

| What | Path |
|---|---|
| containers | `.sda/workflows/<NNN>. <slug>/` |
| state script | `<this-skill-folder>/scripts/workflow.ps1` · `<this-skill-folder>/scripts/workflow.sh` |

`<this-skill-folder>` is the directory containing this `SKILL.md`.

## Entry

- The container is named by the entry prompt or the request — usually with its `issue.md`
  attached. `<wf>` = `.sda/workflows/<NNN>. <slug>`; `<folder>` = the container's folder
  name (`<NNN>. <slug>`).
- Told a container that does not exist → **stop and ask**; never create one — the
  orchestrator's `init` is the only creator.
- Read `<wf>/issue.md` first — it names the issue and the artifact paths.

## Stage gate

Before any work, run `current`. `stage=` is not your stage → **refuse**: report the stage and
stop — its owner runs first. A `gap=<stage>` line means that stage's artifact is absent.

## CLI

`{workflow}` is the script itself — an absolute path, always quoted:

- PowerShell: `& "<this-skill-folder>\scripts\workflow.ps1"`
- Bash: `bash "<this-skill-folder>/scripts/workflow.sh"`

Run every command from the repo root. Never unquote the path, never add `-File` or `-Command`,
never read the script's source — this table is the full interface. On `error=...` →
**🚨 HARD STOP**: print the exact message, end your response.

| Command | PowerShell | Bash/zsh | What it gives you |
|---|---|---|---|
| `list` | `{workflow} list` | `{workflow} list` | one line per container; marks the deepest open escalation |
| `current` | `{workflow} current -slug <folder>` | `{workflow} current --slug <folder>` | `stage=`, any `gap=<stage>`, open escalation (`owner`, `reason`, `brief`) |
| `read` | `{workflow} read -slug <folder> [-field <id\|slug\|created\|stage\|start\|notes>]` | `{workflow} read --slug <folder> [--field <id\|slug\|created\|stage\|start\|notes>]` | one state field, or the whole state |
| `init` | `{workflow} init -slug <slug> [-at <story\|design\|dev>]` | `{workflow} init --slug <slug> [--at <story\|design\|dev>]` | creates the container, its `escalations/` folder, and `workflow.json`, starting at the given stage (default `story`) |
| `advance` | `{workflow} advance -slug <folder>` | `{workflow} advance --slug <folder>` | forward exactly one stage |
| `escalate` | `{workflow} escalate -slug <folder> [-to <stage>] -reason <text> -brief <path>` | `{workflow} escalate --slug <folder> [--to <stage>] --reason <text> --brief <path>` | back one or more stages |
| `resolve` | `{workflow} resolve -slug <folder> -id <E#> -report <text>` | `{workflow} resolve --slug <folder> --id <E#> --report <text>` | close the open escalation, forward one |

Every mutation prints `ok: … -> '<stage>'`; every failure prints `error=<X cannot do Y
because Z>`. On `error=`, print it verbatim and stop. Never retry a rejected transition with
different arguments unless the user asks.

## Stage steps

The three sections below are stage roles' steps. The orchestrator's own steps are in its card.

## Finish — advance

A workflow session never ends at "done" — it ends by advancing or escalating.
Your stage's artifact written and your own gate passed? Ask the user; on an explicit yes run
`advance` and report the stage the `ok:` line names. A `gap=` for your stage is an absent
artifact → surface it and stop instead. Every mutation is user-confirmed.

## Escalate

When the upstream artifact your work rests on proved insufficient:

1. **Discuss before you escalate** — which artifact is short, what it blocks, what the
   upstream stage must re-decide. Escalate only on the user's explicit yes; a "no" is an
   answer — say what stays unresolved and stop.
2. Write the evidence via `sda-scribe` (Mode 8) into `<wf>/escalations/`. The script refuses
   a raise without a brief: retry, and after 3 attempts stop and report.
3. Run `escalate` with `slug`, `reason` = "<what broke · what must be re-decided>", and
   `brief` = the path the scribe returned. The default sends it back one stage; `to` reaches
   further — your card names the targets.
4. Report the new stage and its owner, then stop — that stage's session resumes the work.

## Resolve

When told to address an escalation addressed to your stage:

1. Run `current` — `owner` is not your stage → say so and stop.
2. Read the brief at the `brief=` path, then the artifact it cites. A brief that does not say
   what must be re-decided is a question to ask, never a gap to fill by guessing.
3. **Discuss before you address it** — walk the user through the claim, what you found, and
   what you propose to change; amend nothing until approved.
4. Renew your artifact.
5. Ask the user; on an explicit yes run `resolve` with the escalation's `id` and `report` =
   "<what changed · where · what the downstream must redo>", then report the outcome.

## .sda dependencies

`.sda/` is a dot-prefixed folder that may be hidden from search tools. Access every file by
exact path from the repo root — never search for them. **Never read workflow state from the
container's files — `current` is the only source of it**, including whether an artifact
exists (`gap=<stage>` means that stage's artifact is absent).

`<wf>` = `.sda/workflows/<NNN>. <slug>/` — fixed, and the default root of the state script.

| File | Path |
|---|---|
| containers | `.sda/workflows/<NNN>. <slug>/` |
| issue.md (entry) | `<wf>/issue.md` |
| assets (orchestrator) | `<wf>/assets/` |
| story artifact — `sda-ba` | `<wf>/user-story.md` |
| design artifact — `sda-design` | `<wf>/design.md` |
| dev artifact — implementation session | `<wf>/dev-report.md` |
| escalation briefs | `<wf>/escalations/` |
| state | `<wf>/workflow.json` — written by the script, read only through `current`/`read` |

**Write your role's artifact at the container root, under exactly that name.** The script
reads only that path — a different name, or a subfolder, is an absent artifact: `current`
reports `gap=<your stage>` and `advance` is refused. A stage card adds what else its stage
produces — specs under `{specs-root}`, design docs in the repo's docs tree — but the stage
artifact never moves out of the container root.

The script and the container template ship with this skill: `scripts/workflow.ps1`,
`scripts/workflow.sh`, `assets/workflow-schema.md`.
