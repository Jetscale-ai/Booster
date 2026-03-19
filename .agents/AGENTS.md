# Booster Repository Operations

<!-- markdownlint-disable MD013 -->

**Status:** Operational Details **Scope:** `Jetscale-ai/Booster` only
**Authority:** [Repository Constitution](../AGENTS.md)

---

## 1. Verification Oracles

### Go Validation

```bash
go test -v ./...
```

### Docker Validation

```bash
docker build --target booster-dev -t booster-test:booster-dev .
docker build --target booster -t booster-test:booster .
```

To verify all named stages:

```bash
python3 - <<'PY'
import re, subprocess
from pathlib import Path
stages = re.findall(r'^FROM\\s+.+?\\s+AS\\s+([\\w-]+)\\s*$', Path("Dockerfile").read_text(), re.M)
for stage in stages:
    subprocess.check_call(["docker", "build", "--target", stage, "-t", f"booster-test:{stage}", "."])
PY
```

### Workflow Verification

```bash
gh run list --repo Jetscale-ai/Booster --limit 10
gh run view <run-id> --repo Jetscale-ai/Booster
gh run view <run-id> --repo Jetscale-ai/Booster --log-failed
```

---

## 2. Release Topology

### Reusable Release Workflow

- File: `.github/workflows/release.yml`
- Caller contract:
  - `image_name`
  - optional `languages`
  - optional `dockerfile`
  - optional `test_command`
- This workflow publishes images and exposes release metadata to callers.

### Top-Level Fan-Out

- File: `.github/workflows/booster-release.yml`
- After a successful release on `main`, Booster dispatches:
  - `backend-base/.github/workflows/release-backend-base.yml`
  - `frontend/.github/workflows/pipeline.yml`

---

## 3. Namespace CI Expectations

- Preferred runner profile: `namespace-profile-jetscale-build`
- Preferred checkout: `namespacelabs/nscloud-checkout-action@v8`
- Preferred remote builder setup: `namespacelabs/nscloud-setup-buildx-action@v0`
- Opt JavaScript actions into Node 24 when possible:
  `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`

If a CI warning mentions Node 20, first check whether it comes from:

1. a GitHub-maintained action pinned to an old major
2. a third-party action with `runs.using: node20`
3. a false-positive deprecation annotation after opting into Node 24

---

## 4. Safety Boundaries

- Do not change reusable workflow inputs without updating all known callers.
- Do not remove Docker image tags (`latest`, semantic version, `sha-*`) without
  a deliberate migration plan.
- Do not add runtime tooling to Alpine images unless it is required by multiple
  downstream repositories.
