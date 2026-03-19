# JetScale Booster Constitution

<!-- markdownlint-disable MD013 -->

**Status:** Ratified **Version:** 3.0.0 **Blueprint:** `library`
(`.agents/codex/blueprints/library.md`) **Stack:** `go-mod`
(`.agents/codex/stacks/go-mod.md`) **Authority:**
[Supreme Constitution](https://github.com/Jetscale-ai/Governance/blob/main/AGENTS.md)

This document is the delegated constitution for `Jetscale-ai/Booster`. It adapts
the Governance constitution to a shared CI/CD tooling repository that publishes
base images, reusable workflows, and downstream pipeline handoffs.

---

## 0. Situational Awareness (Required Context)

### 0.1 Universal Red Lines (Excerpt)

- Agents must never execute commits, pushes, or tags.
- Agents must never output, log, or persist secrets.
- Agents must never impersonate humans.

### 0.2 Default Failure Mode

If instructions conflict, evidence is ambiguous, or blast radius is unknown:

1. STOP.
2. AUDIT assumptions and current state.
3. ASK the human before proceeding.

### 0.3 Eudaimonia is 12 Invariants

The Eudaimonia Framework is the full set of 12 universal invariants. Any
`audit_log:` in commits or PRs must cite only the invariants that actually
applied for that change.

### 0.4 Tooling Preflight (Mandatory)

Before bootstrapping canonical law, verify:

```bash
require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }; }

require_cmd gh
gh auth status -h github.com >/dev/null 2>&1 || { echo "gh not authenticated for github.com" >&2; exit 1; }
require_cmd base64
require_cmd sed

# Repo toolchain
require_cmd go
require_cmd docker
```

### 0.5 Load Canonical Law (How)

On each new session, load the ratified Governance artifacts from
`Jetscale-ai/Governance@main` before giving substantive guidance:

```bash
gh api repos/Jetscale-ai/Governance/contents/AGENTS.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/protocols/bootstrap.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/protocols/ratification.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/protocols/audit-trail.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/protocols/ci-monitoring.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/blueprints/library.md --jq .content | base64 -d
gh api repos/Jetscale-ai/Governance/contents/.agents/codex/stacks/go-mod.md --jq .content | base64 -d
```

### 0.6 Hard Stop on Missing Law

If canonical law cannot be retrieved, agents must not invent governance. Enter
Advisory Mode and request human intervention.

### 0.7 Load Local Operations (How)

Load repository-local operations before providing commands or verification
steps:

```bash
sed -n '1,200p' .agents/AGENTS.md
```

Or via GitHub API:

```bash
gh api repos/Jetscale-ai/Booster/contents/.agents/AGENTS.md --jq .content | base64 -d
```

## 0.8 Codex Ratification

This constitution ratifies the following Governance artifacts on
`Jetscale-ai/Governance@main`:

| Artifact               | Path                                       |
| :--------------------- | :----------------------------------------- |
| Supreme Constitution   | `AGENTS.md`                                |
| Bootstrap Protocol     | `.agents/codex/protocols/bootstrap.md`     |
| Ratification Protocol  | `.agents/codex/protocols/ratification.md`  |
| Audit Trail Protocol   | `.agents/codex/protocols/audit-trail.md`   |
| CI Monitoring Protocol | `.agents/codex/protocols/ci-monitoring.md` |
| Library Blueprint      | `.agents/codex/blueprints/library.md`      |
| Go Modules Stack       | `.agents/codex/stacks/go-mod.md`           |

### On-Demand Codex Loading

| Trigger                           | Required Artifact                                        |
| :-------------------------------- | :------------------------------------------------------- |
| Commit and traceability questions | `.agents/codex/protocols/audit-trail.md`                 |
| CI failures after direct pushes   | `.agents/codex/protocols/ci-monitoring.md`               |
| Branch protection questions       | `.agents/codex/protocols/branch-protection.md`           |
| Tooling selection and bootstrap   | `.agents/codex/protocols/tooling-tiers.md`               |
| Commit format                     | `.agents/codex/skills/core/conventional-commit/SKILL.md` |

## 0.9 Repository Declaration

- **Owner:** Paul (Founding Engineer)
- **Risk Level:** Medium
- **Primary Artifact:** Base images and reusable GitHub Actions workflows
- **Downstream Surface:** `thruster -> booster -> backend-base`, and
  `booster -> frontend`
- **Namespace Profile:** `namespace-profile-jetscale-build`

---

## 1. Repository Purpose

Booster is shared operational machinery. It publishes polyglot developer/runtime
images and the reusable release workflow consumed by sibling repositories.

Core mandates:

- Keep the reusable workflow GitHub-native (`workflow_call`, `GITHUB_OUTPUT`,
  least-privilege permissions).
- Use Namespace-backed runner improvements when they reduce CI latency or
  improve determinism.
- Treat CI logs as a user interface: concise, grouped, and free of secret
  leakage.

## 2. Release Contract

- Reusable workflow: `.github/workflows/release.yml`
- Top-level workflow: `.github/workflows/booster-release.yml`
- The reusable workflow is the single release contract for downstream image
  repositories such as `thruster` and `backend-base`.
- Versioning is driven by semantic-release from git history, not by parsing
  language manifests.

## 3. Architectural Invariants

- A single Dockerfile remains the source of truth for polyglot images.
- Dev and runtime stages must remain separated; no build-only tooling in runtime
  images.
- Missing Docker Hub credentials degrade gracefully to GHCR-only publishing.
- Downstream fan-out from top-level workflows must use explicit
  `workflow_dispatch` calls, not implicit image polling.

## 4. Documentation Currency

README, workflow docs, and repo law must match the live codebase:

- Canonical org/repo links should use `Jetscale-ai/*`
- Published image families and tool inventories must reflect the current
  Dockerfile
- Release-chain documentation must reflect the actual dispatch graph
