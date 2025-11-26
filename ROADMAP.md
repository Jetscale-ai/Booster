# Booster Strategic Horizon

**Objective:** Deliver a reusable, polyglot, GitHub-native CI/CD pipeline powered by `go-semantic-release`.

## Phase 1: The Foundation (Artifacts)

> _Goal: A buildable, multi-language Docker image._

- [ ] **The Unified Dockerfile:** Create a single `Dockerfile` with targets:
  - `dev-base` (Ubuntu 24.04)
  - `runtime-base` (Alpine 3.20)
  - `booster-[lang]-dev` (Go, TS, Py)
  - `booster-[lang]` (Runtime)
- [ ] **Local Build Verification:** Verify all targets build locally with `docker buildx`.

## Phase 2: The Brain (Versioning)

> _Goal: Automatic version determination without language dependencies._

- [ ] **Configuration:** Create `.semrel.yaml` for `go-semantic-release`.
  - Configure "Conventional Commits" parser.
  - Define branch rules (`main`, `next`, `beta`, `alpha`).
  - Set tag format `v{{version}}`.
- [ ] **Version Extraction:** Create a proof-of-concept script to run `semantic-release --dry` and capture the calculated version into a variable usable by GitHub Actions.

## Phase 3: The Engine (Workflow)

> _Goal: The Reusable GitHub Action._

- [ ] **Scaffold `release.yml`:** Create `.github/workflows/release.yml`.
- [ ] **Define Inputs:** `image_name`, `languages`, `dockerfile`.
- [ ] **Permissions & Secrets:** Configure explicit permissions and `secrets: inherit`.
- [ ] **The Build Loop:** Implement the logic to loop through requested languages and build/push both Dev and Runtime images.
- [ ] **Caching:** Implement `docker/build-push-action` with `gha` caching.

## Phase 4: Integration (The First Flight)

> _Goal: The Booster repo releases itself._

- [ ] **Self-Consumption:** Create `.github/workflows/ci.yml` in the `booster` repo that calls `release.yml`.
- [ ] **Validation:** Push a commit, verify GHCR contains the tagged images.
- [ ] **Docker Hub Check:** Verify graceful degradation if Docker Hub secrets are missing, or success if present.

## Phase 5: Expansion (Documentation & Adoption)

> _Goal: Zero-friction adoption by other teams._

- [ ] **The Golden Path README:** Write clear instructions on how to call this workflow.
- [ ] **Example Repos:** (Optional) Validate with a "Hello World" Go service repo.
