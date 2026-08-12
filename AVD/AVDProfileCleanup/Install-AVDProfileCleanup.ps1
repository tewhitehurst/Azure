[CmdletBinding()]
param(
  [Parameter()]
  [string] $TriggerType,

  [Parameter()]
  [DayOfWeek[]] $DaysToRun,

  [Parameter()]
  [DateTime] $TimeToRun,

  [Parameter()]
  [string] $TaskUser,

  [Parameter()]
  [switch] $UseLauncher,

  [Parameter()]
  [string] $ConfigFile = ".\AVDProfileCleanup.xml",

  [Parameter()]
  [switch] $OverrideConfig = $false
)

#==================================================
# AVD Profile Cleanup Installer
#==================================================

# Check if the current user has local admin rights
try {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

  if (!$isAdmin) {
    Write-Host "You do NOT have local admin rights.  Local admin rights are required to install this scheduled task; please re-launch from an elevated PowerShell session.  Exiting!" -ForegroundColor Red
    exit
  }
}
catch {
  Write-Host "Error checking admin rights: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Load config
try {
  [xml]$Config = Get-Content $ConfigFile -ErrorAction Stop
  Write-Host "Configuration loaded"
}
catch {
  Write-Host "Unable to load configuration [$ConfigFile], exiting!"
  exit
}

# Process overrides by parameter
if ($OverrideConfig) {
  if ($TriggerType) {$Config.AVDProfileCleanup.Installer.TriggerType = $TriggerType}
  if ($DaysToRun) {$Config.AVDProfileCleanup.Installer.DaysToRun = $DaysToRun}
  if ($TimeToRun) {$Config.AVDProfileCleanup.Installer.TimeToRun = $TimeToRun}
  if ($TaskUser) {$Config.AVDProfileCleanup.Installer.TaskUser = $TaskUser}
  if ($UseLauncher) {$Config.AVDProfileCleanup.Installer.UseLauncher = $UseLauncher}
}

# Set Variables
[string] $TaskName = $Config.AVDProfileCleanup.Installer.TaskName
[string] $TriggerType = $Config.AVDProfileCleanup.Installer.TriggerType
[string[]] $DaysToRun = @($Config.AVDProfileCleanup.Installer.DaysToRun)
[DateTime] $TimeToRun = [DateTime]::Parse($Config.AVDProfileCleanup.Installer.TimeToRun)
[string] $TaskUser = $Config.AVDProfileCleanup.Installer.TaskUser
[switch] $UseLauncher = [bool]::Parse($Config.AVDProfileCleanup.Installer.UseLauncher)

[string] $InstallFolder = $Config.AVDProfileCleanup.Common.InstallFolder

[string] $ScriptUrl = $Config.AVDProfileCleanup.Common.ScriptUrl
[string] $LauncherUrl = $Config.AVDProfileCleanup.Common.LauncherUrl
[string] $ConfigUrl = $Config.AVDProfileCleanup.Common.ConfigUrl

[string] $LocalScript = Join-Path $InstallFolder $Config.AVDProfileCleanup.Common.LocalScript
[string] $LocalLauncher = Join-Path $InstallFolder $Config.AVDProfileCleanup.Common.LocalLauncher
[string] $LocalConfig = Join-Path $InstallFolder $Config.AVDProfileCleanup.Common.LocalConfig

# Create Folder
if (!(Test-Path $InstallFolder)) {
  try {
    New-Item -Path $InstallFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
  }
  catch {
    Write-Host "Unable to create install folder [$InstallFolder], exiting"
    exit
  }
}

# Download Latest Script
Invoke-WebRequest `
    -Uri $ScriptUrl `
    -OutFile $LocalScript `
    -UseBasicParsing

Write-Host "Downloaded latest cleanup script."

# Download Latest Launcher
Invoke-WebRequest `
    -Uri $LauncherUrl `
    -OutFile $LocalLauncher `
    -UseBasicParsing

Write-Host "Downloaded latest launcher script."

# Download Latest Config
Invoke-WebRequest `
    -Uri $ConfigUrl `
    -OutFile $LocalConfig `
    -UseBasicParsing

Write-Host "Downloaded latest config XML."


# Scheduled Task Settings

if ($UseLauncher) {
  $Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$LocalLauncher`"" `
    -WorkingDirectory $InstallFolder
}
else {
  $Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$LocalScript`""
}

switch ($TriggerType) {
  "Weekly" {
    $Trigger = New-ScheduledTaskTrigger `
      -Weekly `
      -DaysOfWeek $DaysToRun `
      -At $TimeToRun
  }

  default {
    Write-Host "Unsupported task trigger [$TriggerType], exiting!"
    exit
  }
}

$Principal = New-ScheduledTaskPrincipal `
  -UserId $TaskUser `
  -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries

# Create / Replace Scheduled Task
try {
  Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Force `
    -ErrorAction Stop | Out-Null

  Write-Host "Scheduled task created/updated."
}
catch {
  Write-Host "Unable to create scheduled task, exiting!"
  exit
}

Write-Host "Installation complete."
