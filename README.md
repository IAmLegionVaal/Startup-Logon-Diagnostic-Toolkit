# Startup Logon Diagnostic Toolkit

A PowerShell toolkit for Windows startup and sign-in triage and selected guarded repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Startup_Logon_Diagnostic_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Startup_Logon_Repair_Toolkit.ps1 -RestartExplorer -DryRun
```

Examples:

```powershell
.\Startup_Logon_Repair_Toolkit.ps1 -RestartExplorer
.\Startup_Logon_Repair_Toolkit.ps1 -ClearIconCache
.\Startup_Logon_Repair_Toolkit.ps1 -RepairWinlogonDefaults
.\Startup_Logon_Repair_Toolkit.ps1 -DisableScheduledTask 'Example Startup Task'
.\Startup_Logon_Repair_Toolkit.ps1 -RunSfc
```

## What the repair does

- Restarts Windows Explorer.
- Rebuilds the current user’s Explorer icon cache.
- Backs up and restores the standard Winlogon `Shell` and `Userinit` values.
- Disables one explicitly selected scheduled task.
- Runs System File Checker when selected.
- Captures startup, task and Winlogon state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

Incorrect Winlogon or scheduled-task changes can affect sign-in and startup. Registry backup is created before Winlogon repair. The tool does not delete startup commands, user profiles or credentials automatically.

## Author

Dewald Pretorius — L2 IT Support Engineer
