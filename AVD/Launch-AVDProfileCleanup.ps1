$ScriptUrl = "https://raw.githubusercontent.com/tewhitehurst/Azure/main/AVD/Clean-LocalProfiles.ps1"
$LocalScript = "C:\ProgramData\AVDProfileCleanup\Clean-LocalProfiles.ps1"

$LocalScriptPath = Split-Path $LocalScript -Parent

if (!(Test-Path $LocalScriptPath)) {
  try {
    New-Item -Path $LocalScriptPath -ItemType Directory -Force -ErrorAction Stop
  }
  catch {
    Write-Host "Unable to create log directory [$LocalScriptPath], exiting"
    exit
  }
}

Invoke-WebRequest `
  -Uri $ScriptUrl `
  -OutFile $LocalScript `
  -UseBasicParsing

& $LocalScript -ExcludedUsers azAdmin,azUser -LogFile C:\Logs\AVDProfileCleanup.log
