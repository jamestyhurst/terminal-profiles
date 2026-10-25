# Extra interactive Bash setup: history, transcripts, completions, ble.sh.
# Sourced from ~/.bashrc after the interactive-shell guard.

# Fallback if ~/.bashrc did not set this (portable install).
__bash_profile_start=${__bash_profile_start:-${EPOCHREALTIME-}}

# --- History (shared, timestamped, large) -----------------------------------
HISTSIZE=50000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T  '
HISTCONTROL=ignoreboth:erasedups
HISTFILE="${HISTFILE:-$HOME/.bash_history}"
shopt -s histappend cmdhist lithist

# --- User-local tools -------------------------------------------------------
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi
if [ -d "$HOME/.cargo/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.cargo/bin:"*) ;;
        *) PATH="$HOME/.cargo/bin:$PATH" ;;
    esac
fi
if command -v fresh >/dev/null 2>&1; then
    export EDITOR="${EDITOR:-fresh}"
    export VISUAL="${VISUAL:-fresh}"
    export GIT_EDITOR="${GIT_EDITOR:-fresh}"
fi

# --- Transcript directory ---------------------------------------------------
export TERMINAL_LOG_DIR="${TERMINAL_LOG_DIR:-$HOME/projects/terminal-logs}"
mkdir -p "$TERMINAL_LOG_DIR"
chmod 700 "$TERMINAL_LOG_DIR" 2>/dev/null || true

# Full TTY capture with script(1) only outside Warp. Warp already owns the
# PTY/block model, so wrapping it would break input and session restore.
if [[ -z ${UNDER_SCRIPT-} \
   && -z ${WARP_IS_LOCAL_SHELL_SESSION-} \
   && -z ${WARP_TERMINAL_SESSION_UUID-} \
   && -t 0 && -t 1 ]]; then
  export UNDER_SCRIPT=1
  export TERMINAL_TRANSCRIPT="$TERMINAL_LOG_DIR/$(date +%Y-%m-%d)_session-${$}.transcript"
  exec script -q -a -f -e "$TERMINAL_TRANSCRIPT"
fi

# Older sessions exported UNDER_SCRIPT without TERMINAL_TRANSCRIPT.
if [[ -n ${UNDER_SCRIPT-} && -z ${TERMINAL_TRANSCRIPT-} ]]; then
  TERMINAL_TRANSCRIPT=$(ls -t "$TERMINAL_LOG_DIR"/*_session-*.transcript 2>/dev/null | head -n 1)
  export TERMINAL_TRANSCRIPT
fi

stop-transcript() {
  if [[ -z ${UNDER_SCRIPT-} ]]; then
    printf 'No session transcript is running.\n' >&2
    return 1
  fi
  printf 'Transcript saved: %s\n' "${TERMINAL_TRANSCRIPT-unknown}"
  exit "${1:-0}"
}
alias Stop-Transcript=stop-transcript

# Command journal: timestamp, pid, exit status, cwd, command.
# Runs in Warp and elsewhere. Dedupes when PROMPT_COMMAND fires twice.
__termlog_last_n=
__termlog_ready=
__termlog_prompt() {
  local status=$?
  history -a
  local hist_line n cmd
  hist_line=$(HISTTIMEFORMAT= history 1)
  n=$(sed -n 's/^[[:space:]]*\([0-9][0-9]*\).*/\1/p' <<<"$hist_line")
  if [[ -z ${__termlog_ready-} ]]; then
    __termlog_ready=1
    __termlog_last_n=$n
    return "$status"
  fi
  [[ -n $n && $n != "$__termlog_last_n" ]] || return "$status"
  __termlog_last_n=$n
  cmd=$(sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//' <<<"$hist_line")
  [[ -n $cmd ]] || return "$status"
  printf '%s | pid=%s | status=%s | cwd=%s | %s\n' \
    "$(date -Iseconds)" "$$" "$status" "$PWD" "$cmd" \
    >> "$TERMINAL_LOG_DIR/$(date +%Y-%m-%d).commands.log"
  return "$status"
}

case ":${PROMPT_COMMAND-}:" in
  *:__termlog_prompt:*) ;;
  *) PROMPT_COMMAND="__termlog_prompt${PROMPT_COMMAND:+;}${PROMPT_COMMAND-}" ;;
esac

# --- ble.sh: syntax highlighting, ghost text, context-aware completion ------
# Skip inside Warp: Warp's input editor already provides these and does not
# use GNU Readline, so ble.sh cannot attach to it.
if [[ -z ${WARP_IS_LOCAL_SHELL_SESSION-} && -z ${WARP_TERMINAL_SESSION_UUID-} ]]; then
  if [[ -f $HOME/.local/share/blesh/ble.sh ]]; then
    # shellcheck disable=SC1091
    source -- "$HOME/.local/share/blesh/ble.sh"
  fi
fi

# Machine-specific extras (not tracked). Copy local.sh.example to enable.
if [[ -f $HOME/.config/bash/local.sh ]]; then
  # shellcheck disable=SC1091
  source -- "$HOME/.config/bash/local.sh"
fi

# Two-line startup notice, outside Warp only.
if [[ -t 1 && -z ${WARP_IS_LOCAL_SHELL_SESSION-} && -z ${WARP_TERMINAL_SESSION_UUID-} ]]; then
  __ms=?
  if [[ -n ${__bash_profile_start-} && -n ${EPOCHREALTIME-} ]]; then
    __s=${__bash_profile_start} __e=${EPOCHREALTIME}
    __s_frac=${__s#*.}000000; __e_frac=${__e#*.}000000
    __ms=$(( (${__e%.*} * 1000 + 10#${__e_frac:0:6} / 1000) - (${__s%.*} * 1000 + 10#${__s_frac:0:6} / 1000) ))
  fi
  printf 'Profile loaded in %s ms.\n' "$__ms"
  if [[ -n ${TERMINAL_TRANSCRIPT-} ]]; then
    printf 'Transcript started: %s\n' "$TERMINAL_TRANSCRIPT"
  elif [[ -n ${UNDER_SCRIPT-} ]]; then
    printf 'Transcript is running (path unknown). Files are in %s\n' "$TERMINAL_LOG_DIR"
  fi
  unset __ms __s __e __s_frac __e_frac
fi
unset __bash_profile_start
