# ==========================================
# 0. Global Setup
# ==========================================
# USES: JetScale Thruster (Ubuntu 24.04 + Base Tools)
FROM ghcr.io/jetscale-ai/thruster-dev:latest AS dev-base

# Add build-essential (GCC/G++) and Starship
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://starship.rs/install.sh | sh -s -- -y \
    && echo 'eval "$(starship init bash)"' >> /root/.bashrc

# USES: JetScale Thruster (Alpine 3.20 + Hardened Runtime)
# Inherits: tini, ca-certificates, tzdata, bash, curl
FROM ghcr.io/jetscale-ai/thruster:latest AS runtime-base

# Test Assets (Source Code)
FROM dev-base AS assets
COPY test /test

# ==========================================
# 1. Base Toolchains (Clean)
# ==========================================

# --- Go Base ---
FROM dev-base AS base-dev-go
ARG GO_VERSION=1.25.4
RUN curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"
RUN go install github.com/magefile/mage@latest

# --- TS Base ---
FROM dev-base AS base-dev-ts
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm ts-node typescript \
    && rm -rf /var/lib/apt/lists/*

# --- Py Base ---
FROM dev-base AS base-dev-py
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://install.python-poetry.org | python3 - \
    && curl -Ls https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# --- Polyglot Base ---
FROM dev-base AS base-dev-poly

# 1. Inherit Go Toolchain & Tools (Mage)
COPY --from=base-dev-go /usr/local/go /usr/local/go
COPY --from=base-dev-go /root/go/bin /root/go/bin
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# 2. Inherit Node.js (Native)
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs

# 3. Inherit Python & Global NPM Tools
COPY --from=base-dev-ts /usr/local/bin /usr/local/bin
COPY --from=base-dev-ts /usr/lib/node_modules /usr/lib/node_modules
COPY --from=base-dev-py /root/.local /root/.local
ENV PATH="/root/.local/bin:/root/go/bin:${PATH}"
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip python3-venv

# ==========================================
# 4. PLATFORM ORCHESTRATION TOOLS
#    (Kind, Tilt, Helm, Kubectl)
# ==========================================

# Kind (via Go)
RUN go install sigs.k8s.io/kind@latest

# Helm (via Script)
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm get_helm.sh

# Kubectl (Binary)
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Tilt (via Script)
RUN curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash

# Clean up
RUN rm -rf /root/.cache /go/pkg/mod

# ==========================================
# 2. DEV VERIFICATION (Logic Tests + Artifact Prep)
# ==========================================
# Here we run the "Heavy" tests (Unit Tests) and build the "Light" tests (Smoke Artifacts).

# --- Go Logic Check ---
FROM base-dev-go AS test-dev-go
COPY --from=assets /test/go /tmp/test-go
# A. Run Logic/Unit Tests (Requires Toolchain)
RUN cd /tmp/test-go && go run main.go
# B. Build Standalone Smoke Binary (For Runtime Check)
#    This binary relies solely on libc, no other dependencies.
RUN cd /tmp/test-go && go build -o /tmp/artifacts/smoke-go main.go
RUN touch /tmp/PASSED

# --- TS Logic Check ---
FROM base-dev-ts AS test-dev-ts
COPY --from=assets /test/ts /tmp/test-ts
# A. Run Logic/Unit Tests (Requires ts-node/DevDeps)
RUN cd /tmp/test-ts && ts-node index.ts
# B. Transpile to Standalone JS (For Runtime Check)
#    This script relies solely on standard node libs.
RUN mkdir -p /tmp/artifacts && \
    cd /tmp/test-ts && tsc index.ts --outfile /tmp/artifacts/smoke-ts.js
RUN touch /tmp/PASSED

# --- Py Logic Check ---
FROM base-dev-py AS test-dev-py
COPY --from=assets /test/py /tmp/test-py
# A. Run Logic Tests
RUN cd /tmp/test-py && python3 main.py
# B. Prepare Smoke Script (For Runtime Check)
RUN mkdir -p /tmp/artifacts && cp /tmp/test-py/main.py /tmp/artifacts/smoke-py.py
RUN touch /tmp/PASSED

# --- Polyglot Integration Check ---
FROM base-dev-poly AS test-dev-poly
WORKDIR /app
# Gather Smoke Artifacts
COPY --from=test-dev-go /tmp/artifacts/smoke-go .
COPY --from=test-dev-ts /tmp/artifacts/smoke-ts.js .
COPY --from=test-dev-py /tmp/artifacts/smoke-py.py .
COPY --from=assets /test/verify_polyglot.sh .
COPY --from=assets /test/verify_versions.sh .
# Update script to look for "smoke-*" instead of "app-*"
RUN sed -i 's/app-/smoke-/g' verify_polyglot.sh
# Run Integration Check
RUN chmod +x verify_polyglot.sh verify_versions.sh && \
    ./verify_versions.sh && \
    ./verify_polyglot.sh
RUN touch /tmp/PASSED

# ==========================================
# 3. Final Release Images
# ==========================================

# --- DEV IMAGES ---
# Depend on Dev Tests passing.
FROM base-dev-go AS booster-go-dev
COPY --from=test-dev-go /tmp/PASSED /dev/null

# Build Metadata Injection (Dev)
# NOTE: Injected here (final stage) to avoid invalidating heavy base caches.
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-dev-ts AS booster-ts-dev
COPY --from=test-dev-ts /tmp/PASSED /dev/null

# Build Metadata Injection (Dev)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-dev-py AS booster-py-dev
COPY --from=test-dev-py /tmp/PASSED /dev/null

# Build Metadata Injection (Dev)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-dev-poly AS booster-dev
COPY --from=test-dev-poly /tmp/PASSED /dev/null

# Build Metadata Injection (Dev)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

# --- RUNTIME IMAGES ---
# Depend on Runtime Capability Checks (Smoke Tests).
# We mount the artifacts. If they run, the image is good.
# We DO NOT install any dev dependencies.

FROM runtime-base AS base-run-go
RUN apk add --no-cache libc6-compat

FROM runtime-base AS base-run-js
RUN apk add --no-cache nodejs npm

FROM runtime-base AS base-run-py
ARG PLAYWRIGHT_VERSION=1.48.0
ENV VIRTUAL_ENV=/opt/venv
RUN apk add --no-cache \
        python3 \
        py3-pip \
        py3-virtualenv \
        git \
        curl \
        unzip \
        nodejs \
        npm \
        chromium \
        chromium-chromedriver \
        nss \
        freetype \
        ttf-freefont \
        harfbuzz \
        libstdc++ \
    && python3 -m venv "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel \
    && "${VIRTUAL_ENV}/bin/pip" install --no-cache-dir "git+https://github.com/microsoft/playwright-python.git@v${PLAYWRIGHT_VERSION}" \
    && SITE_PACKAGES="$("${VIRTUAL_ENV}/bin/python3" -c 'import site; print(site.getsitepackages()[0])')" \
    && DRIVER_DIR="${SITE_PACKAGES}/playwright/driver" \
    && mkdir -p "${DRIVER_DIR}" \
    && curl -fsSL "https://playwright.azureedge.net/builds/driver/playwright-${PLAYWRIGHT_VERSION}-linux.zip" -o /tmp/playwright-driver.zip \
    && unzip -q /tmp/playwright-driver.zip -d /tmp/playwright-driver \
    && cp /tmp/playwright-driver/LICENSE "${DRIVER_DIR}/LICENSE" \
    && if [ -f /tmp/playwright-driver/README.md ]; then cp /tmp/playwright-driver/README.md "${DRIVER_DIR}/README.md"; fi \
    && cp -R /tmp/playwright-driver/package "${DRIVER_DIR}/" \
    && rm -rf /tmp/playwright-driver /tmp/playwright-driver.zip \
    && PLAYWRIGHT_NODEJS_PATH=/usr/bin/node "${VIRTUAL_ENV}/bin/playwright" install chromium
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PLAYWRIGHT_NODEJS_PATH=/usr/bin/node

FROM runtime-base AS base-run-poly
RUN apk add --no-cache libc6-compat nodejs npm python3

# RELEASE TARGETS
# The RUN --mount instructions act as the verification step.
# If these commands fail, the build fails.
# If they succeed, the artifacts vanish, leaving a clean image.

FROM base-run-go AS booster-go
RUN --mount=from=test-dev-go,source=/tmp/artifacts/smoke-go,target=/tmp/check \
    /tmp/check

# Build Metadata Injection (Runtime)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-run-js AS booster-js
RUN --mount=from=test-dev-ts,source=/tmp/artifacts/smoke-ts.js,target=/tmp/check.js \
    node /tmp/check.js

# Build Metadata Injection (Runtime)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-run-py AS booster-py
RUN --mount=from=test-dev-py,source=/tmp/artifacts/smoke-py.py,target=/tmp/check.py \
    python3 /tmp/check.py

# Build Metadata Injection (Runtime)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"

FROM base-run-poly AS booster
RUN --mount=from=test-dev-poly,source=/app,target=/tmp/tests \
    cd /tmp/tests && ./verify_polyglot.sh

# Build Metadata Injection (Runtime)
ARG JETSCALE_VERSION=0.0.0-dev
ARG JETSCALE_GIT_SHA=unknown
ARG JETSCALE_BUILD_TIME=unknown
ENV BOOSTER_VERSION="${JETSCALE_VERSION}" \
    BOOSTER_COMMIT_SHA="${JETSCALE_GIT_SHA}" \
    BOOSTER_BUILD_TIME="${JETSCALE_BUILD_TIME}"
