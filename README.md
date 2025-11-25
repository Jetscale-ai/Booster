# Booster

**Booster** is the heavy-lift infrastructure for JetScale's CI/CD pipeline. It provides:

1. **Unified Base Images**: Polyglot Docker images for Go, TypeScript, and Python.
2. **Reusable CI/CD Workflow**: A single GitHub Action that handles semantic versioning, Docker building, and publishing.

## Images

We publish two families of images to GHCR (and optionally Docker Hub):

### 1. Dev Images (`-dev`)

Based on **Ubuntu 24.04**. Includes build tools (curl, git, build-essential) and language toolchains.
Intended for: **CI Build Jobs**, **DevContainers**, **Local Development**.

- `ghcr.io/jetscale/booster-dev` (Polyglot)
- `ghcr.io/jetscale/booster-go-dev`
- `ghcr.io/jetscale/booster-ts-dev`
- `ghcr.io/jetscale/booster-py-dev`

### 2. Runtime Images (no suffix)

Based on **Alpine 3.20**. Minimal footprint.
Intended for: **Production Containers**.

- `ghcr.io/jetscale/booster`
- `ghcr.io/jetscale/booster-go`
- `ghcr.io/jetscale/booster-ts`
- `ghcr.io/jetscale/booster-py`

## The Golden Path: Reusable CI/CD

To enable fully automated releases in your project, simply create a `.github/workflows/release.yml` file:

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    uses: jetscale/booster/.github/workflows/release.yml@main
    with:
      image_name: my-service-name
      languages: 'go' # or "ts", "py", "go,ts"
    secrets: inherit
```

**Prerequisites:**

1. Ensure your repo has a valid `Dockerfile`.
   - If using `languages: "go"`, your Dockerfile must have targets `booster-go-dev` and `booster-go` (or rely on the default behavior if you don't need multi-stage splitting in the standard way, though the workflow currently targets specific stages).
2. Ensure `GITHUB_TOKEN` has write access to packages (for GHCR).
3. (Optional) Set `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` in repository secrets to publish to Docker Hub.

## Development

### Repo Layout

- `Dockerfile`: Single multi-stage file defining all image variants.
- `.github/workflows/release.yml`: The core logic.
- `.semrel.yaml`: Configuration for `go-semantic-release`.

### Adding a new language

1. Update `Dockerfile`:
   - Add `booster-<lang>-dev` stage (Ubuntu).
   - Add `booster-<lang>` stage (Alpine).
2. Update `release.yml` if any special handling is needed (the loop is generic).
3. Update `README.md`.

## Local Testing (act)

We use [nektos/act](https://github.com/nektos/act) to run GitHub Actions locally.

1. Install `act` (e.g., `brew install act`).
2. Create a `.secrets` file in the root (gitignored) with your credentials

   ```sh
   DOCKERHUB_USERNAME=youruser
   DOCKERHUB_TOKEN=yourtoken
   GITHUB_TOKEN=yourtoken # Optional, act usually mocks this
   ```

3. Run the release workflow:

   ```bash
   mage LocalRelease
   ```

   Or manually:

   ```bash
   act push -j release --secret-file .secrets
   ```

## License

MIT
