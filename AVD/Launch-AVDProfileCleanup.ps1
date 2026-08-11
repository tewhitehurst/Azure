# Load local configuration
$ConfigFile = ".\AVDProfileCleanup.xml"

try {
  [xml]$Config = Get-Content $ConfigFile -ErrorAction Stop
  Write-Host "Configuration loaded"
}
catch {
  Write-Host "Unable to load configuration [$ConfigFile], exiting!"
  exit
}

# Refresh config
$ConfigUrl = $Config.AVDProfileCleanup.Common.ConfigUrl

Invoke-WebRequest `
    -Uri $ConfigUrl `
    -OutFile $ConfigFile `
    -UseBasicParsing

try {
  [xml]$Config = Get-Content $ConfigFile -ErrorAction Stop
  Write-Host "Configuration refreshed & re-loaded"
}
catch {
  Write-Host "Unable to load configuration [$ConfigFile], exiting!"
  exit
}

# Set Variables
[string] $InstallFolder = $Config.AVDProfileCleanup.Common.InstallFolder
[string] $ScriptUrl = $Config.AVDProfileCleanup.Common.ScriptUrl
[string] $LocalScript = Join-Path $InstallFolder $Config.AVDProfileCleanup.Common.LocalScript

if (!(Test-Path $InstallFolder)) {
  try {
    New-Item -Path $InstallFolder -ItemType Directory -Force -ErrorAction Stop
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

& $LocalScript
