# The Eudaimonia Framework: Booster Protocol

This is the **Constitution** for all AI agents and human contributors working on the `booster` repository.

## 1. Ethos (Character & Being)

1. **Legitimacy (GitHub-Native):** All solutions must use **native GitHub Actions paradigms** (DooD, `workflow_call`, `GITHUB_OUTPUT`). We do not port legacy scripts; we reimplement intent using modern primitives.
2. **Identity (The Booster Metaphor):** We build "Boosters"—heavy lift vehicles (images/workflows) that get other projects into orbit. We are infrastructure, not the payload. We must be reliable, reusable, and robust.
3. **Purpose (Frictionless Release):** Our sole purpose is to allow a developer to drop 10 lines of YAML into their repo and achieve a perfect, secure, multi-arch release pipeline.
4. **Aisthesis (The Aesthetic of Logs):** CI logs are our user interface. We ensure `go-semantic-release` and `docker` outputs are clean, grouped, and debuggable. We do not pollute the console with raw secrets or unformatted JSON.

## 2. Logos (Reason & Internal Order)

5. **Prudence (Security & Caching):**
   - **Permissions:** We operate with Least Privilege. We explicitly define `permissions: { contents: write, packages: write }`. We never rely on implicit token scopes.
   - **Secrets:** We assume `secrets: inherit` but validate critical secrets (Docker Hub) exist before attempting operations that require them.
   - **Caching:** GitHub Runners are ephemeral. We **must** implement `cache-from: type=gha` and `cache-to: type=gha` for Docker builds to avoid 10-minute build times.
6. **Clarity (The Single Source of Truth):** `go-semantic-release` is the **sole** arbiter of versioning. We do not parse `package.json`, `pyproject.toml`, or `go.mod` for versions. The Git history drives the tag.
7. **Vigor (Performance):** We use Multi-Stage Builds to separate "Dev" (Heavy/Ubuntu) from "Runtime" (Lean/Alpine). We do not ship build tools to production.
8. **Elenchus (Testing the Pipe):** We verify our own workflows. The `booster` repo itself must use the `release.yml` workflow to release its own images.

## 3. Praxis (Action & Interaction)

9. **Concord (Polyglot Unity):** We support Go, TypeScript, and Python from a **single** Dockerfile and a **single** workflow. We do not fracture into separate repos for each language.
10. **Symbiosis (The Caller Contract):** We respect the interface. The caller provides the `image_name` and `languages`. We provide the machinery. We do not break this contract without a major version bump.
11. **Justice (Graceful Degradation):** If Docker Hub credentials are missing, we warn and continue (pushing only to GHCR). We do not fail the pipeline for optional external registries.
12. **Wisdom (Evolution):** We anticipate new languages (Rust, Java). Our `for` loops and matrix strategies must be extensible via simple string inputs, not code refactors.

## Operational Mandates

- **No DinD Service:** Use the runner's native Docker daemon.
- **No Raw Shell Output:** Capture outputs via `$GITHUB_OUTPUT`.
- **Strict Tagging:** Always push `:commit-sha`, `:version`, and `:latest`.
