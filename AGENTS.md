# Shikigami — AI Agent Scrum Team Framework

> 7 AI teammates, each with distinct responsibilities and mutual checks — giving your AI development tool a disciplined engineering team.

This file is the OpenCode entry point for the Shikigami framework (analogous to `CLAUDE.md` in Claude Code environments). It describes the framework structure, role definitions, and OpenCode-specific configuration.

---

## Framework Overview

Shikigami is a **plugin framework** that injects 7 specialized roles (Shikigami) into your AI development tool. They form a **mutual governance network**: QA reviews your code and challenges architectural decisions, Security reviews external inputs, SRE evaluates deployment feasibility. Use natural language to describe what you want — the Scrum Master automatically dispatches the appropriate roles.

**Current version: v0.3.11** (17 Skills / 7 Agents / 4 Commands)

---

## OpenCode Skills Loading Path

Shikigami Skills are available in OpenCode via the `.opencode/skills/` directory (symlinked from `skills/`).

OpenCode scans the following paths to discover SKILL.md files:

```
.opencode/skills/*/SKILL.md   ← primary path (symlink → skills/)
skills/*/SKILL.md              ← fallback (git worktree)
```

All 17 Shikigami Skills are accessible under `.opencode/skills/`:

```
.opencode/skills/
├── scrum-master/SKILL.md
├── sprint-planning/SKILL.md
├── sprint-execution/SKILL.md
├── sprint-review/SKILL.md
├── backlog-management/SKILL.md
├── escalation/SKILL.md
├── architecture-decision/SKILL.md
├── quality-gate/SKILL.md
├── security-review/SKILL.md
├── deployment-readiness/SKILL.md
├── systematic-debugging/SKILL.md
├── dispel/SKILL.md
├── git-workflow/SKILL.md
├── parallel-dispatch/SKILL.md
├── issue-management/SKILL.md
├── health-check/SKILL.md
└── onboarding/SKILL.md
```

---

## Role Definitions

### 7 Roles (Shikigami)

| Role | Responsibility | Trigger |
|------|---------------|---------|
| **Scrum Master** | Auto-dispatch Agent Scrum Team roles and Sprint flow | Intent detection, Sprint ceremonies |
| **Product Owner** | Requirements definition, priority decisions, Backlog management | Requirements discussion, Sprint planning, feature prioritization |
| **Architect** | Architecture decisions, SDD authoring, technology selection | Technology selection, system design, performance analysis |
| **Developer** | Feature implementation, TDD development, Bug fixes | Sprint execution, code writing, technical implementation |
| **QA Engineer** | Code review, test strategy, quality gate | Feature completion, PR review, quality inspection |
| **Security Engineer** | Security scanning, vulnerability assessment, OWASP checks | External input handling, API endpoints, configuration changes |
| **SRE Engineer** | Deployment checks, monitoring configuration, environment management | Deployment preparation, version releases, environment changes |

**Key principle: They check each other.** Not 7 independent assistants — a disciplined engineering team.

---

## OpenCode-Specific Configuration

### Skills Invocation

In OpenCode, Skills are invoked by referencing their name. The Scrum Master SKILL.md orchestrates subagent dispatch using the Task tool.

### Subagent Dispatch

OpenCode's native Task tool supports programmatic subagent dispatch. Shikigami's 5 core roles (PO / Architect / QA / Developer / SM) are dispatched via Task tool calls within SKILL.md orchestration logic.

### Known Compatibility Notes (Phase 1)

The following items require verification in a live OpenCode environment (Phase 2 POC):

1. **Task tool parameter format** — OpenCode Task tool is similar to Claude Code's but parameter field naming may differ; cross-reference OpenCode docs before executing complex dispatch chains.
2. **SessionStart hook equivalent** — Shikigami uses Claude Code's `SessionStart` hook for framework initialization; the equivalent mechanism in OpenCode requires live investigation.
3. **`claude -p` references** — Some SKILL.md sections reference `claude -p` (Claude Code CLI invocation); these are informational/example snippets and do not affect OpenCode runtime behavior.

### Project Configuration

Create a `CLAUDE.md` (or equivalent project config) in your project root using the template:

```bash
cp templates/CLAUDE.md.template ./CLAUDE.md
```

Adjust the following for your project:
- Project name and tech stack
- Development constraints
- Document directory structure
- Quick-start commands

### Project Autonomy Level

Set project level in your project config to control AI team autonomy:

| Level | Use Case | Behavior |
|-------|----------|----------|
| **low** | Personal projects, experiments | Full autonomy, all operations execute automatically |
| **medium** (default) | General development projects | Low-risk auto, high-risk reviewed by QA before execution |
| **high** | Important products, public repos | Low-risk auto, high-risk requires human confirmation |

---

## Document Index

| Document | Purpose |
|----------|---------|
| [README.md](./README.md) | Full feature description, role overview, 17 Skills |
| [Getting Started](docs/tutorial/GETTING_STARTED.md) | End-to-end onboarding from install to first Sprint |
| [Troubleshooting](docs/tutorial/TROUBLESHOOTING.md) | 6 common failure scenarios with diagnosis and resolution |
| [Product Backlog](docs/prd/PRODUCT_BACKLOG.md) | RICE-scored prioritized backlog |
| [Project Board](docs/PROJECT_BOARD.md) | Sprint progress and artifact navigation |
| [OpenCode POC Report](docs/km/OPENCODE_POC.md) | OpenCode platform integration analysis and Go/No-Go decision |

---

## Quick Start (OpenCode)

1. Open OpenCode in your project directory
2. Say what you want to do in natural language — the Scrum Master will dispatch automatically:

```
> Initialize Shikigami for my project
> Start Sprint Planning
> Implement US-01
> Run Sprint Review
```

Or trigger Skills directly by name:

```
> Use sprint-planning skill
> Use sprint-execution skill
```

---

## Related

- [OpenCode Skills Documentation](https://opencode.ai/docs/skills/)
- [OpenCode Agents Documentation](https://opencode.ai/docs/agents/)
- [Shikigami OpenCode POC Report](docs/km/OPENCODE_POC.md)
