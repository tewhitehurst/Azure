[CmdletBinding()]
param(
  [Parameter()]
  [int] $DaysToKeep,

  [Parameter()]
  [switch] $DeleteProfiles,

  [Parameter()]
  [string[]] $ExcludedUsers,

  [Parameter()]
  [string] $LogFile,

  [Parameter()]
  [string] $ConfigFile = ".\AVDProfileCleanup.xml",

  [Parameter()]
  [switch] $OverrideConfig = $false

)

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
  if ($DaysToKeep) {$Config.AVDProfileCleanup.Cleanup.DaysToKeep = $DaysToKeep}
  if ($DeleteProfiles) {$Config.AVDProfileCleanup.Cleanup.DeleteProfiles = $DeleteProfiles}
  if ($ExcludedUsers) {$Config.AVDProfileCleanup.Cleanup.ExcludedUsers = $ExcludedUsers}
  if ($LogFile) {$Config.AVDProfileCleanup.Cleanup.LogFile = $LogFile}
}

# Set Variables
[int] $DaysToKeep = $Config.AVDProfileCleanup.Cleanup.DaysToKeep
[switch] $DeleteProfiles = [bool]::Parse($Config.AVDProfileCleanup.Cleanup.DeleteProfiles)
[string[]] $ExcludedUsers = @($Config.AVDProfileCleanup.Cleanup.ExcludedUsers)
[string] $LogFile = $Config.AVDProfileCleanup.Cleanup.LogFile

# Process parameters/variables
if ($ExcludedUsers -notcontains "Administrator") {
  $ExcludedUsers += "Administrator"
}

$LogPath = Split-Path $LogFile -Parent
$CutoffDate = (Get-Date).AddDays(-$DaysToKeep)

# Check for log directory and create if needed
if (!(Test-Path $LogPath)) {
  try {
    New-Item -Path $LogPath -ItemType Directory -Force -ErrorAction Stop
  }
  catch {
    Write-Host "Unable to create log directory [$LogPath], exiting"
    exit
  }
}

# Simple logging function
function Write-Log {
    param([string]$Message)

    $Line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') : $Message"

    $Line | Out-File $LogFile -Append
    Write-Host $Line
}

# Startup
Write-Log "$($MyInvocation.MyCommand.Name) started"
Write-Log "  DaysToKeep = $DaysToKeep"
Write-Log "  DeleteProfiles = $DeleteProfiles"
Write-Log "  Excluded Users = $ExcludedUsers"
Write-Log "  LogFile = $LogFile"

# Collect users with sessions
$SessionUsers = @()

try {
    $SessionUsers = (
        quser 2>$null |
        Select-Object -Skip 1 |
        ForEach-Object {
            ($_ -replace '^\s+','' -split '\s+')[0] -replace '^\>',''
        }
    )
    Write-Log "Retrieved current user sessions"
}
catch {
  Write-Log "Unable to retrieve current user sessions"
}

# Collect local profiles
$Profiles = Get-CimInstance Win32_UserProfile
Write-Log "Retrieved local user profiles"

# Parse the pofiles
foreach ($Profile in $Profiles) {
  $UserName = Split-Path $Profile.LocalPath -Leaf
  
  if ($Profile.Special) {
    Write-Log "Special user: $UserName, skipping"
    continue
  }

  if ($Profile.Loaded) {
    Write-Log "Active user: $UserName, skipping"
    continue
  }

  if (!$Profile.LastUseTime) {
    Write-Log "Missing LastUseTime: $UserName, skipping"
    continue
  }

  if ($ExcludedUsers -contains $UserName) {
    Write-Log "Excluded user: $UserName, skipping"
    continue
  }

  if ($SessionUsers -contains $UserName) {
    Write-Log "User has session: $UserName"
    continue
  }

  $LastUsed = $Profile.LastUseTime
  if ($LastUsed -ge $CutoffDate) {
    continue
  }

  Write-Log "Candidate: $UserName LastUsed=$LastUsed"

  # Delete/report profiles for cleanup
  if ($DeleteProfiles) {
    try {
      #Remove-CimInstance -InputObject $Profile -ErrorAction Stop
      Write-Log "Deleted: $UserName"
    }
    catch {
      Write-Log "Failed: $UserName $_"
    }
  }
  else {
    Write-Log "ReportOnly: $UserName"
  }
}

# Finish
Write-Log "$($MyInvocation.MyCommand.Name) finished"
