# terminal-profiles

Portable shell profiles for Linux/Ubuntu bash and Windows PowerShell 7+. Clone this repo on a new machine and run the installer for that OS.

```text
terminal-profiles/
  linux-ubuntu/           # bash, readline, ble.sh, transcripts
  windows-powershell/     # pwsh 7+, PSReadLine, Start-Transcript
```

Both sides aim for the same feel: tab completion from the current directory, ghost-text suggestions, syntax highlighting, large shared history, and automatic session transcripts under `~/projects/terminal-logs/`.

On Linux, Tab prefers files and folders already in `$PWD`. An empty first word lists the current directory; a typed prefix still includes matching PATH commands after local paths. `cd` completes directories only. Warp ignores GNU Readline / ble.sh, but it still asks bash for the completions menu.

Warp already provides highlighting and ghost text in its own input editor. These profiles skip the extra line-editor and `script` wrapping inside Warp so they do not fight it.

## Linux / Ubuntu

```bash
git clone https://github.com/jamestyhurst/terminal-profiles.git
cd terminal-profiles/linux-ubuntu
bash install.sh
```

`install.sh` copies:

- `~/.config/bash/interactive.sh`
- `~/.inputrc`
- `~/.local/bin/termlogs`

and appends a marked block to `~/.bashrc`. It also installs [ble.sh](https://github.com/akinomyoga/ble.sh) if it is missing (syntax highlighting and ghost text outside Warp).

Open a **new terminal window** (Ptyxis: `ptyxis --new-window`). You should see:

```text
Profile loaded in 87 ms.
Transcript started: /home/you/projects/terminal-logs/2026-10-25_session-12345.transcript
```

End the recorded session with `stop-transcript` (or `exit` / Ctrl-D).

Machine-specific aliases go in `~/.config/bash/local.sh` (copied from `bash/local.sh.example` on first install; not overwritten later).

## Windows / PowerShell 7+

In PowerShell 7:

```powershell
git clone https://github.com/jamestyhurst/terminal-profiles.git
cd terminal-profiles/windows-powershell
./install.ps1
```

This writes `$PROFILE` (`Microsoft.PowerShell_profile.ps1`) and enables PSReadLine inline predictions (ghost text from history). Transcripts start automatically. Stop them with the built-in:

```powershell
Stop-Transcript
```

`local.ps1` next to `$PROFILE` is the machine-specific overlay.

The same profile works in pwsh on Linux if you want one PowerShell setup everywhere.

## Logs

| File | What |
| --- | --- |
| `~/projects/terminal-logs/YYYY-MM-DD.commands.log` | Command journal (bash) |
| `~/projects/terminal-logs/YYYY-MM-DD_session-PID.transcript` | Full session transcript |

`script` / `Start-Transcript` record the whole session, including typed input.

Override the directory with `TERMINAL_LOG_DIR`.

## License

MIT
