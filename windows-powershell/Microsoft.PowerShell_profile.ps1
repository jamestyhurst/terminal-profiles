#requires -Version 7.0
# PowerShell 7+ profile: history, PSReadLine ghost text, transcripts.
$script:ProfileStart = Get-Date

function Test-InWarp {
    [bool](
        $env:WARP_IS_LOCAL_SHELL_SESSION -or
        $env:WARP_TERMINAL_SESSION_UUID -or
        $env:TERM_PROGRAM -eq 'WarpTerminal'
    )
}

function Add-HomePath([string]$Dir) {
    if (-not (Test-Path -LiteralPath $Dir)) { return }
    $parts = $env:PATH -split [IO.Path]::PathSeparator
    if ($parts -notcontains $Dir) {
        $env:PATH = $Dir + [IO.Path]::PathSeparator + $env:PATH
    }
}

Add-HomePath (Join-Path $HOME '.local/bin')
Add-HomePath (Join-Path $HOME '.cargo/bin')

if (Get-Command fresh -ErrorAction SilentlyContinue) {
    if (-not $env:EDITOR) { $env:EDITOR = 'fresh' }
    if (-not $env:VISUAL) { $env:VISUAL = 'fresh' }
    if (-not $env:GIT_EDITOR) { $env:GIT_EDITOR = 'fresh' }
}

$env:TERMINAL_LOG_DIR = if ($env:TERMINAL_LOG_DIR) {
    $env:TERMINAL_LOG_DIR
} else {
    Join-Path $HOME 'projects/terminal-logs'
}
New-Item -ItemType Directory -Force -Path $env:TERMINAL_LOG_DIR | Out-Null

$interactive = [Environment]::UserInteractive -and $Host.Name -eq 'ConsoleHost'
if ($interactive -and -not (Test-InWarp) -and -not $env:TERMINAL_TRANSCRIPT) {
    $stamp = Get-Date -Format 'yyyy-MM-dd'
    $env:TERMINAL_TRANSCRIPT = Join-Path $env:TERMINAL_LOG_DIR "${stamp}_session-${PID}.transcript"
    Start-Transcript -Path $env:TERMINAL_TRANSCRIPT -Append | Out-Null
}

if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -MaximumHistoryCount 50000
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

function Get-TermLogs {
    param(
        [Parameter(Position = 0)]
        [ValidateSet('list', 'today', 'path')]
        [string]$Command = 'list'
    )
    $dir = $env:TERMINAL_LOG_DIR
    switch ($Command) {
        'path' { $dir; break }
        'today' {
            $f = Join-Path $dir ("{0}.commands.log" -f (Get-Date -Format 'yyyy-MM-dd'))
            if (Test-Path $f) { Get-Content $f } else { Write-Error "No journal yet: $f" }
        }
        default { Get-ChildItem $dir | Sort-Object LastWriteTime -Descending }
    }
}

$local = Join-Path (Split-Path -Parent $PROFILE) 'local.ps1'
if (Test-Path -LiteralPath $local) {
    . $local
}

if ($interactive -and -not (Test-InWarp)) {
    $ms = [int][math]::Round(((Get-Date) - $script:ProfileStart).TotalMilliseconds)
    Write-Host "Profile loaded in $ms ms."
    if ($env:TERMINAL_TRANSCRIPT) {
        Write-Host "Transcript started: $($env:TERMINAL_TRANSCRIPT)"
    }
}
