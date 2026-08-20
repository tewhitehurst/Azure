# AVD Profile Cleanup Utility

This repository contains scripts and configuration files used to manage cached local profiles on Azure Virtual Desktop (AVD) session hosts.

## Repository Files

### `AVDProfileCleanup.xml`

Contains the configuration settings used by the scripts.

Default settings include:

- Log-only mode (`DeleteProfiles` is set to `false`)
- 7-day retention
- Ignore users named `azAdmin`, `azUser`, and `Administrator`
- Write logs to `C:\Logs\AVDProfileCleanup\CleanLocalProfiles.log`

### `Clean-LocalProfiles.ps1`

Runs on the host system to enumerate cached profiles and remove them based on the criteria defined in `AVDProfileCleanup.xml`.

### `Install-AVDProfileCleanup.ps1`

Installs and configures the profile cleanup solution on the host system. The installer:

- Verifies that it is running with administrator rights
- Loads configuration from `AVDProfileCleanup.xml`, which must be in the same directory as the installer, and applies any command-line overrides
- Creates the installation folder, which defaults to `C:\ProgramData\AVDProfileCleanup`
- Downloads the following files from the GitHub repository to the installation folder:
  - `Clean-LocalProfiles.ps1`
  - `Launch-AVDProfileCleanup.ps1`
  - `AVDProfileCleanup.xml`
- Creates a scheduled task using the defaults defined in the configuration file:
  - **Name:** AVD Profile Cleanup
  - **Trigger:** Weekly on Sunday at 3:00 AM
  - **User:** `SYSTEM`
  - **Action:** Executes `Clean-LocalProfiles.ps1` with options loaded from the configuration file at runtime

### `Launch-AVDProfileCleanup.ps1`

Provides a wrapper around `Clean-LocalProfiles.ps1` with additional update functionality. The launcher:

- Retrieves the latest configuration file from the defined URL and reloads it, allowing changes to a source configuration to be applied automatically during the next scheduled execution
- Retrieves the latest version of `Clean-LocalProfiles.ps1` from the defined URL
- Executes `Clean-LocalProfiles.ps1` with options loaded from the configuration file at runtime

## Quick Testing

> [!NOTE]
> The following approach is recommended for quick testing only.

1. Download these files from the repository:
   - `Install-AVDProfileCleanup.ps1`
   - `AVDProfileCleanup.xml`
2. Open PowerShell as an administrator.
3. Change to the directory where the installation files were saved.
4. Run the installer:

   ```powershell
   .\Install-AVDProfileCleanup.ps1
   ```

This creates the basic scheduled task and configures it to launch `Clean-LocalProfiles.ps1` directly. You can then modify the local configuration file to adjust the cleanup behavior.

## Production Deployment

For longer-term or production use:

1. Store the scripts and configuration file in a small Azure Blob Storage account that the session hosts can access.
2. Run the installer with the launcher and configuration override options:

   ```powershell
   .\Install-AVDProfileCleanup.ps1 -UseLauncher -OverrideConfig
   ```

3. Update the configuration to reference the Blob Storage URLs instead of the GitHub repository URLs.

This approach allows the launcher to retrieve updated configuration and cleanup scripts dynamically at runtime.
