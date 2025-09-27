#region Version Information (MANDATORY - Regelwerk v9.6.0)
$ScriptVersion = "v7.1.0"  # Updated for v9.6.0 compliance
$RegelwerkVersion = "v9.6.0"
$BuildDate = "2025-09-27"
$Author = "Flecki (Tom) Garnreiter"

<#
.VERSION HISTORY
v7.1.0 - 2025-09-27 - Updated to Regelwerk v9.6.0 compliance, added cross-script communication
v7.0.0 - Previous - MedUni Wien Kalercherl integration
v6.x.x - Previous versions - Standard AD user creation functionality
#>
#endregion

#region Script Information Display (MANDATORY - Regelwerk v9.6.0)
function Show-ScriptInfo {
    param(
        [string]$ScriptName = "AD User Creation System",
        [string]$CurrentVersion = $ScriptVersion
    )
    
    Write-Host "🚀 $ScriptName v$CurrentVersion" -ForegroundColor Green
    Write-Host "📅 Build: $BuildDate | Regelwerk: $RegelwerkVersion" -ForegroundColor Cyan
    Write-Host "👤 Author: $Author" -ForegroundColor Cyan
    Write-Host "💻 Server: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "📂 Repository: Useranlage (AD User Creation)" -ForegroundColor Magenta
    Write-Host "🏢 Integration: MedUni Wien Kalercherl" -ForegroundColor Blue
}
#endregion

#region Cross-Script Communication (MANDATORY - Regelwerk v9.6.0)
function Send-UseranlageMessage {
    param(
        [string]$TargetScript,
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $MessageDir = "LOG\Messages"
    if (-not (Test-Path $MessageDir)) {
        New-Item -Path $MessageDir -ItemType Directory -Force | Out-Null
    }
    
    $MessageFile = "$MessageDir\$TargetScript-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $MessageData = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Source = "AD-User_Anlage.ps1"
        Target = $TargetScript
        Message = $Message
        Type = $Type
        RegelwerkVersion = $RegelwerkVersion
        UserContext = $env:USERNAME
    }
    
    $MessageData | ConvertTo-Json | Out-File $MessageFile -Encoding UTF8
    Write-Verbose "Message sent to $TargetScript: $Message"
}

function Set-UseranlageStatus {
    param(
        [string]$Status,
        [hashtable]$Details = @{}
    )
    
    $StatusDir = "LOG\Status"
    if (-not (Test-Path $StatusDir)) {
        New-Item -Path $StatusDir -ItemType Directory -Force | Out-Null
    }
    
    $StatusFile = "$StatusDir\AD-User_Anlage-Status.json"
    $StatusData = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Script = "AD-User_Anlage.ps1"
        Status = $Status
        Details = $Details
        RegelwerkVersion = $RegelwerkVersion
        Version = $ScriptVersion
        UserContext = $env:USERNAME
    }
    
    $StatusData | ConvertTo-Json | Out-File $StatusFile -Encoding UTF8
    Write-Verbose "Status updated: $Status"
}

function Send-ADCreationNotification {
    param(
        [string]$UserCreated,
        [string]$Department,
        [string]$Status
    )
    
    $NotificationMessage = "AD User Creation: $UserCreated | Department: $Department | Status: $Status"
    Send-UseranlageMessage -TargetScript "CertSurv-System" -Message $NotificationMessage -Type "AD_NOTIFICATION"
    Send-UseranlageMessage -TargetScript "ResetProfile-System" -Message "New user created: $UserCreated - Profile reset may be required" -Type "PROFILE_NOTIFICATION"
}
#endregion

# Export version information for other scripts
Export-ModuleMember -Variable ScriptVersion, RegelwerkVersion, BuildDate, Author -Function Show-ScriptInfo, Send-UseranlageMessage, Set-UseranlageStatus, Send-ADCreationNotification

Write-Verbose "VERSION.ps1 loaded - AD User Creation System v$ScriptVersion (Regelwerk $RegelwerkVersion)"