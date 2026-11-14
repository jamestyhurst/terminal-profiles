# terminal-profiles

A PowerShell 7+ profile for Windows that makes the shell nicer to live in: ghost-text
suggestions from history, a large shared history, and automatic session transcripts under
`~/projects/terminal-logs/`. It also works in pwsh on macOS and Linux, if you want one
PowerShell setup everywhere.

The bash profile for Linux that used to live here was retired on 2026-11-14. Its last version
is in the history at commit `4a5feb3`, under `linux-ubuntu/`.

## Install

In PowerShell 7:

```powershell
git clone https://github.com/jamestyhurst/terminal-profiles.git
cd terminal-profiles/windows-powershell
./install.ps1
```

This writes `$PROFILE` (`Microsoft.PowerShell_profile.ps1`) and enables PSReadLine inline
predictions (ghost text from history). Transcripts start automatically. Stop them with the
built-in:

```powershell
Stop-Transcript
```

`local.ps1` next to `$PROFILE` is the machine-specific overlay; start from
`windows-powershell/local.ps1.example`.

Warp already provides ghost text and highlighting in its own input editor, so the profile skips
transcripts inside Warp rather than fight it.

## Logs

| File | What |
| --- | --- |
| `~/projects/terminal-logs/YYYY-MM-DD_session-PID.transcript` | Full session transcript |

`Start-Transcript` records the whole session, including typed input, so never print a secret
into a terminal you want to keep private. `Get-TermLogs` lists the folder. Override the folder
with `TERMINAL_LOG_DIR`.

## License

MIT
