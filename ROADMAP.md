# Booster Strategic Horizon

**Objective:** Deliver a reusable, polyglot, GitHub-native CI/CD pipeline
powered by `go-semantic-release`.

## Phase 1: The Foundation (Artifacts) ✅

> _Goal: A buildable, multi-language Docker image._

- [x] **The Unified Dockerfile:** Create a single `Dockerfile` with targets:
  - `dev-base` (Ubuntu 24.04)
  - `runtime-base` (Alpine 3.20)
  - `booster-[lang]-dev` (Go, TS, Py)
  - `booster-[lang]` (Runtime)
- [x] **Local Build Verification:** Verify all targets build locally with
      `docker buildx`.

## Phase 2: The Brain (Versioning) ✅

> _Goal: Automatic version determination without language dependencies._

- [x] **Configuration:** Create `.semrel.yaml` for `go-semantic-release`.
  - Configure "Conventional Commits" parser.
  - Define branch rules (`main`, `next`, `beta`, `alpha`).
  - Set tag format `v{{version}}`.
- [x] **Version Extraction:** Implemented via `go-semantic-release/action` in
      the reusable workflow.

## Phase 3: The Engine (Workflow) ✅

> _Goal: The Reusable GitHub Action._

- [x] **Scaffold `release.yml`:** Create `.github/workflows/release.yml`.
- [x] **Define Inputs:** `image_name`, `languages`, `dockerfile`.
- [x] **Permissions & Secrets:** Configure explicit permissions and
      `secrets: inherit`.
- [x] **The Build Loop:** Implement the logic to loop through requested
      languages and build/push both Dev and Runtime images.
- [x] **Caching:** Implement `docker/build-push-action` with `gha` caching.

## Phase 4: Integration (The First Flight) 🚧

> _Goal: The Booster repo releases itself._

- [x] **Self-Consumption:** Create `.github/workflows/booster-release.yml` in
      the `booster` repo that calls `release.yml`.
- [ ] **Validation:** Push a commit to `main`, verify GHCR contains the tagged
      images.
- [ ] **Docker Hub Check:** Verify graceful degradation if Docker Hub secrets
      are missing, or success if present.
- [ ] **Release Verification:** Verify the `latest` and `vX.Y.Z` tags are
      correctly applied.

## Phase 5: Expansion (Documentation & Adoption) 📅

> _Goal: Zero-friction adoption by other teams._

- [ ] **The Golden Path README:** Write clear instructions on how to call this
      workflow.
- [ ] **Consumer Verification:** Create a separate "Hello World" repository (or
      integration test harness) that consumes the published `booster` action to
      prove reusability.
