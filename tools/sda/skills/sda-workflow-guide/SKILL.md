---
name: sda-workflow-guide
description: "Workflow-mode operating instructions for SDA stage agents — the workflow CLI, the stage gate, and the finish/escalate/resolve steps. Use when: a stage agent (sda-ba, sda-design, sda-dev-task, sda-dev) is running a session declared as workflow mode by its entry prompt or a request naming a container."
---

# Workflow Mode

You are a stage agent running in **workflow mode**. A workflow is a numbered container
(`.sda/workflows/<NNN>. <slug>/`) holding one issue's artifacts plus script-written state
(`workflow.json`). This skill is the workflow machinery — the CLI, the gate, and the
finish/escalate/resolve steps. Your stage's specifics live in your stage card:

| Your agent | Card |
|---|---|
| `sda-ba` | [`assets/stage-story.md`](assets/stage-story.md) |
| `sda-design` | [`assets/stage-design.md`](assets/stage-design.md) |
| `sda-dev-task` | [`assets/stage-tasks.md`](assets/stage-tasks.md) |
| `sda-dev` | [`assets/stage-dev.md`](assets/stage-dev.md) |

Read your card first. It names your stage, your artifact, your input, who you escalate to,
and when you may `advance`.

## Entry

- The container is named by the entry prompt or the request — usually with its `issue.md`
  attached. `<wf>` = `{workflows-root}/<NNN>. <slug>`; `<folder>` = the container's folder
  name (`<NNN>. <slug>`).
- Told a container that does not exist → **stop and ask**; never create one — `init` belongs
  to `sda-workflow`.
- Read `<wf>/issue.md` first — it names the issue and the artifact paths.

## Stage gate

Before any work, run `current`. `stage=` is not your stage → **refuse**: report the stage and
stop — its owner runs first. A `gap=<stage>` line means that stage's artifact is absent;
`gap=dev` is followed by `missing=<folder>, <folder>` — the task folders still owing a
`dev-report.md`.

## CLI

**Use the raw relative path — no `&`, no quotes, no absolute paths, no `bash`/`sh`/`zsh` prefix.** On `error=...` →
**🚨 HARD STOP**: print the exact message, end your response. Never read the script's source —
this table is the full interface.

| Placeholder | Session context key |
|---|---|
| `{workflow}` | `scripts.workflow` |
| `{workflows-root}` | `paths.workflows` |

| Command | PowerShell | Bash/zsh | What it gives you |
|---|---|---|---|
| `current` | `{workflow} current -slug <folder>` | `{workflow} current --slug <folder>` | `stage=`, any `gap=<stage>`, open escalation (`owner`, `reason`, `brief`) |
| `read` | `{workflow} read -slug <folder> [-field <id\|slug\|created\|stage\|start\|notes>]` | `{workflow} read --slug <folder> [--field <id\|slug\|created\|stage\|start\|notes>]` | one state field, or the whole state |
| `advance` | `{workflow} advance -slug <folder>` | `{workflow} advance --slug <folder>` | forward exactly one stage |
| `escalate` | `{workflow} escalate -slug <folder> [-to <stage>] -reason <text> -brief <path>` | `{workflow} escalate --slug <folder> [--to <stage>] --reason <text> --brief <path>` | back one or more stages |
| `resolve` | `{workflow} resolve -slug <folder> -id <E#> -report <text>` | `{workflow} resolve --slug <folder> --id <E#> --report <text>` | close the open escalation, forward one |

Every mutation prints `ok: … -> '<stage>'`; every failure prints `error=<X cannot do Y
because Z>`. On `error=`, print it verbatim and stop. Never retry a rejected transition with
different arguments unless the user asks.

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

| File | Path |
|---|---|
| workflow containers | `{workflows-root}/<NNN>. <slug>/` |
| issue.md (entry) | `{workflows-root}/<NNN>. <slug>/issue.md` |
| stage artifact | `{workflows-root}/<NNN>. <slug>/<your-artifact>` — see your card |
| escalation briefs | `{workflows-root}/<NNN>. <slug>/escalations/` |
| workflow script | `{workflow}` |

The workflow root and script are injected at session start by the read-config hook.
