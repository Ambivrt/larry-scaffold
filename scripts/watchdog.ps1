# watchdog.ps1 -- Auto-restart daemons that crash
# Polls every 60 seconds, restarts any daemon whose PID file is missing or stale.
# Run as a background process via larry-start.ps1 or Task Scheduler.
#
# Configure $VaultPath and the $daemons registry below.

param(
    [string]$VaultPath = $env:VAULT_ROOT
)

if (-not $VaultPath) {
    Write-Error "VAULT_ROOT not set and -VaultPath not provided"
    exit 1
}

$ErrorActionPreference = "Continue"
$NotifDir = Join-Path $VaultPath ".notifications"
$LogFile  = Join-Path $NotifDir "watchdog.log"

if (-not (Test-Path $NotifDir)) {
    New-Item -Path $NotifDir -ItemType Directory -Force | Out-Null
}

$env:PYTHONIOENCODING = "utf-8"

# === Daemon registry ===
# Customize: add your own daemons here.
# Each entry needs Name, PidFile, LockFile (optional), Script, and WorkDir.
$daemons = @(
    @{
        Name     = "Parry"
        PidFile  = "parry-guardian.pid"
        LockFile = "parry-guardian.lock"
        Script   = Join-Path $VaultPath "bus\parry_service.py"
        WorkDir  = Join-Path $VaultPath "bus"
    }
    @{
        Name     = "Tarry"
        PidFile  = "tarry.pid"
        LockFile = "tarry.lock"
        Script   = Join-Path $VaultPath "agents\tarry_service.py"
        WorkDir  = Join-Path $VaultPath "agents"
    }
    @{
        Name     = "Carry"
        PidFile  = "carry.pid"
        LockFile = "carry.lock"
        Script   = Join-Path $VaultPath "agents\carry_service.py"
        WorkDir  = Join-Path $VaultPath "agents"
    }
    @{
        Name     = "Bot-listener"
        PidFile  = "bot-listener.pid"
        LockFile = "bot-listener.lock"
        Script   = Join-Path $VaultPath "notifications\bot_listener.py"
        WorkDir  = Join-Path $VaultPath "notifications"
    }
    @{
        Name     = "Event-dispatcher"
        PidFile  = "event-dispatcher.pid"
        LockFile = "event-dispatcher.lock"
        Script   = Join-Path $VaultPath "agents\event_dispatcher.py"
        WorkDir  = Join-Path $VaultPath "agents"
    }
)

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts [watchdog] $Msg"
    $line | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Test-DaemonAlive {
    param([string]$PidFile)
    $pidPath = Join-Path $NotifDir $PidFile
    if (-not (Test-Path $pidPath)) { return $false }
    $dpid = (Get-Content $pidPath -Raw).Trim()
    try {
        $proc = Get-Process -Id $dpid -ErrorAction Stop
        if ($proc.ProcessName -match "python") { return $true }
    } catch { }
    return $false
}

function Clear-StaleFiles {
    param([string]$PidFile, [string]$LockFile)
    $pidPath = Join-Path $NotifDir $PidFile
    if (Test-Path $pidPath) { Remove-Item $pidPath -Force -ErrorAction SilentlyContinue }
    if ($LockFile) {
        $lockPath = Join-Path $NotifDir $LockFile
        if (Test-Path $lockPath) { Remove-Item $lockPath -Force -ErrorAction SilentlyContinue }
    }
}

function Restart-Daemon {
    param([hashtable]$Daemon)
    Clear-StaleFiles -PidFile $Daemon.PidFile -LockFile $Daemon.LockFile
    $dname = $Daemon.Name.ToLower()
    $errFile = Join-Path $NotifDir "$dname.log.err"
    $proc = Start-Process -FilePath "pythonw" -ArgumentList $Daemon.Script -WorkingDirectory $Daemon.WorkDir -WindowStyle Hidden -PassThru -RedirectStandardError $errFile
    Start-Sleep -Milliseconds 800
    if ($proc.HasExited) {
        return $false
    }
    return $true
}

# PID file for watchdog itself
$watchdogPid = Join-Path $NotifDir "watchdog.pid"
"$PID" | Out-File -FilePath $watchdogPid -Encoding ascii -NoNewline

Write-Log "started (pid=$PID), poll=60s"

while ($true) {
    foreach ($d in $daemons) {
        $alive = Test-DaemonAlive -PidFile $d.PidFile
        if (-not $alive) {
            $dname = $d.Name
            Write-Log "$dname DOWN - restarting"
            if ($dname -eq "Parry") {
                Start-Sleep -Milliseconds 500
            }
            $ok = Restart-Daemon -Daemon $d
            if ($ok) {
                $newPidPath = Join-Path $NotifDir $d.PidFile
                $dpid = ""
                if (Test-Path $newPidPath) { $dpid = (Get-Content $newPidPath -Raw).Trim() }
                Write-Log "$dname restarted (pid=$dpid)"
            } else {
                Write-Log "$dname FAILED to restart"
            }
        }
    }
    Start-Sleep -Seconds 60
}
