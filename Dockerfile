# ==========================================
# Stage 1: Dev Base (Ubuntu 24.04)
# ==========================================
FROM ubuntu:24.04 AS dev-base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Common tools for all dev images
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    build-essential \
    tini \
    jq \
    vim \
    openssh-client \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# Language Specific Dev Layers
# ==========================================

# --- Go Dev ---
FROM dev-base AS booster-go-dev
ARG GO_VERSION=1.22.2
RUN curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:${PATH}"
# Verify
RUN go version

# --- TypeScript/Node Dev ---
FROM dev-base AS booster-ts-dev
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm \
    && rm -rf /var/lib/apt/lists/*
# Verify
RUN node -v && pnpm -v

# --- Python Dev ---
FROM dev-base AS booster-py-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*
# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"
# Verify
RUN python3 --version && poetry --version

# --- Polyglot Dev (All-in-one) ---
FROM dev-base AS booster-dev
# Install Go
COPY --from=booster-go-dev /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"
# Install Node/pnpm (re-running script here or copying artifacts is tricky with apt, easier to re-run setup for stability)
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pnpm
# Install Python/Poetry
RUN apt-get install -y --no-install-recommends python3 python3-pip python3-venv
COPY --from=booster-py-dev /root/.local /root/.local
ENV PATH="/root/.local/bin:${PATH}"
RUN rm -rf /var/lib/apt/lists/*

# ==========================================
# Stage 2: Runtime Base (Alpine)
# ==========================================
FROM alpine:3.20 AS runtime-base

RUN apk add --no-cache \
    ca-certificates \
    tini \
    bash

ENTRYPOINT ["/sbin/tini", "--"]

# ==========================================
# Language Specific Runtime Layers
# ==========================================

# --- Go Runtime ---
FROM runtime-base AS booster-go
# Go binaries are usually static, but libc compat might be needed
RUN apk add --no-cache libc6-compat

# --- TypeScript/Node Runtime ---
FROM runtime-base AS booster-ts
RUN apk add --no-cache nodejs npm

# --- Python Runtime ---
FROM runtime-base AS booster-py
RUN apk add --no-cache python3

# --- Polyglot Runtime ---
# (Rarely used, but provided for symmetry)
FROM runtime-base AS booster
RUN apk add --no-cache \
    libc6-compat \
    nodejs \
    npm \
    python3

