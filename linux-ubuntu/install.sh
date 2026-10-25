#!/usr/bin/env bash
# Install Ubuntu/Linux bash profile files into the current account.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
BASHRC="${HOME}/.bashrc"
MARKER_START='# >>> terminal-profiles >>>'
MARKER_END='# <<< terminal-profiles <<<'
TIMER_START='# >>> terminal-profiles-timer >>>'
TIMER_END='# <<< terminal-profiles-timer <<<'

mkdir -p "${HOME}/.config/bash" "${HOME}/.local/bin" "${HOME}/.local/share" \
  "${HOME}/projects/terminal-logs"
chmod 700 "${HOME}/projects/terminal-logs" 2>/dev/null || true

cp "${ROOT}/bash/interactive.sh" "${HOME}/.config/bash/interactive.sh"
cp "${ROOT}/inputrc" "${HOME}/.inputrc"
cp "${ROOT}/bin/termlogs" "${HOME}/.local/bin/termlogs"
chmod +x "${HOME}/.local/bin/termlogs"

if [[ ! -f ${HOME}/.config/bash/local.sh && -f ${ROOT}/bash/local.sh.example ]]; then
  cp "${ROOT}/bash/local.sh.example" "${HOME}/.config/bash/local.sh"
fi

touch "$BASHRC"

if ! grep -qF "$TIMER_START" "$BASHRC" && ! grep -qF '__bash_profile_start' "$BASHRC"; then
  if grep -q '^esac$' "$BASHRC"; then
    # Insert the load-time timer after the first interactive-shell guard.
    awk -v start="$TIMER_START" -v end="$TIMER_END" '
      { print }
      !done && $0 == "esac" {
        print ""
        print start
        print "__bash_profile_start=${EPOCHREALTIME-}"
        print end
        done=1
      }
    ' "$BASHRC" > "${BASHRC}.terminal-profiles.tmp"
    mv "${BASHRC}.terminal-profiles.tmp" "$BASHRC"
  else
    {
      printf '\n%s\n' "$TIMER_START"
      printf '%s\n' '__bash_profile_start=${EPOCHREALTIME-}'
      printf '%s\n' "$TIMER_END"
    } >> "$BASHRC"
  fi
fi

if ! grep -qF "$MARKER_START" "$BASHRC" && ! grep -q 'config/bash/interactive.sh' "$BASHRC"; then
  cat >> "$BASHRC" <<EOF

${MARKER_START}
if [ -f "\$HOME/.config/bash/interactive.sh" ]; then
    . "\$HOME/.config/bash/interactive.sh"
fi
${MARKER_END}
EOF
fi

if [[ ! -f ${HOME}/.local/share/blesh/ble.sh ]]; then
  if command -v wget >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    tmp=$(mktemp -d)
    wget -qO "${tmp}/ble-nightly.tar.xz" \
      https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz
    tar -xJf "${tmp}/ble-nightly.tar.xz" -C "$tmp"
    bash "${tmp}"/ble-nightly/ble.sh --install "${HOME}/.local/share"
    rm -rf "$tmp"
  else
    printf 'install.sh: wget/tar missing; skip ble.sh (syntax highlighting / ghost text).\n' >&2
  fi
fi

printf 'Installed Linux/Ubuntu profile.\n'
printf '  ~/.config/bash/interactive.sh\n'
printf '  ~/.inputrc\n'
printf '  ~/.local/bin/termlogs\n'
printf 'Open a new terminal window (not Warp) to load it.\n'
