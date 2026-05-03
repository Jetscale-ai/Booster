# Shared GPG agent setup for Jetscale devcontainers.
if command -v gpg-connect-agent >/dev/null 2>&1; then
    jetscale_gpg_agent_probe="$(gpg-connect-agent /bye 2>&1 || true)"
    case "${jetscale_gpg_agent_probe}" in
        *restricted*)
            gpgconf --kill all >/dev/null 2>&1 || true
            rm -f "${GNUPGHOME:-${HOME}/.gnupg}"/S.gpg-agent* 2>/dev/null || true
            gpg-agent --daemon --allow-loopback-pinentry >/dev/null 2>&1 || true
            ;;
    esac
    unset jetscale_gpg_agent_probe
fi

export GPG_TTY="$(tty 2>/dev/null || true)"
