#requires -Version 5.1
<#
.SYNOPSIS
    Startup Logon Diagnostic Toolkit.
.DESCRIPTION
    Read-only startup and logon context reporter for Windows support.
#>
[CmdletBinding()]
param([string]$OutputPath,[int]$Hours=48)

$RunStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Startup_Logon_Reports' }
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
function Export-Data { param($Name,$Data) $Data | Export-Csv (Join-Path $OutputPath "$Name.csv") -NoTypeInformation -Encoding UTF8; $Data | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputPath "$Name.json") -Encoding UTF8 }
$os = Get-CimInstance Win32_OperatingSystem
$startup = Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location,User
$users = Get-CimInstance Win32_LoggedOnUser -ErrorAction SilentlyContinue
$start = (Get-Date).AddHours(-1*$Hours)
$events = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=$start;Level=1,2,3} -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -match 'Winlogon|User Profile|GroupPolicy|Service Control Manager' } | Select-Object -First 150 TimeCreated,Id,ProviderName,LevelDisplayName,Message
$summary = [PSCustomObject]@{Computer=$env:COMPUTERNAME;CurrentUser="$env:USERDOMAIN\$env:USERNAME";LastBoot=$os.LastBootUpTime;StartupItemCount=@($startup).Count;Generated=Get-Date}
Export-Data -Name "startup_items_$RunStamp" -Data $startup
Export-Data -Name "logon_events_$RunStamp" -Data $events
Export-Data -Name "summary_$RunStamp" -Data @($summary)
$html = "<h1>Startup Logon Diagnostic - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary) | ConvertTo-Html -Fragment)<h2>Startup Items</h2>$($startup | ConvertTo-Html -Fragment)<h2>Recent Events</h2>$($events | ConvertTo-Html -Fragment)"
$html | ConvertTo-Html -Title 'Startup Logon Diagnostic' | Set-Content (Join-Path $OutputPath "startup_logon_$RunStamp.html") -Encoding UTF8
$summary | Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
