[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$RestartExplorer,
 [switch]$RepairWinlogonDefaults,
 [switch]$ClearIconCache,
 [string]$DisableScheduledTask,
 [switch]$RunSfc,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'StartupLogonRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json';$regBackup=Join-Path $run 'winlogon.reg'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Winlogon=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue|Select-Object Shell,Userinit;Explorer=Get-Process explorer -ErrorAction SilentlyContinue|Select-Object Id,StartTime;Startup=Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue|Select-Object Name,Command,Location,User;FailedTasks=Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object State -eq 'Disabled'|Select-Object -First 50 TaskName,TaskPath,State}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
if(-not($RestartExplorer -or $RepairWinlogonDefaults -or $ClearIconCache -or $DisableScheduledTask -or $RunSfc)){Write-Error 'Choose at least one repair action.';exit 2}
if(($RepairWinlogonDefaults -or $DisableScheduledTask -or $RunSfc) -and -not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected startup and logon repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($RepairWinlogonDefaults){Act 'Backing up Winlogon registry key' {& reg.exe export 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' $regBackup /y|Out-Null;if($LASTEXITCODE){throw 'Registry export failed'}};Act 'Restoring standard Winlogon Shell and Userinit values' {Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' Shell 'explorer.exe';Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' Userinit "$env:SystemRoot\system32\userinit.exe,"}}
if($DisableScheduledTask){$task=Get-ScheduledTask -TaskName $DisableScheduledTask -ErrorAction Stop;Act "Disabling scheduled task $($task.TaskPath)$($task.TaskName)" {Disable-ScheduledTask -InputObject $task|Out-Null}}
if($ClearIconCache){Act 'Rebuilding current-user Explorer icon cache' {Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue;Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue|Remove-Item -Force -ErrorAction SilentlyContinue;Start-Process explorer.exe}}
elseif($RestartExplorer){Act 'Restarting Windows Explorer' {Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue;Start-Sleep 2;Start-Process explorer.exe}}
if($RunSfc){Act 'Running System File Checker' {$p=Start-Process sfc.exe -ArgumentList '/scannow' -Wait -PassThru -NoNewWindow;if($p.ExitCode -notin 0,1){throw "SFC exited $($p.ExitCode)"}}}
Start-Sleep 2;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
