# --- FL-Maintenance.psm1 ---
#
# Modul für Wartungsfunktionen
#
# Author:         Flecki (Tom) Garnreiter
# Created on:     2025.09.03
# Last modified:  2025.09.03
# Version:        v1.0.0
# MUW-Regelwerk:  v9.0.9
# Copyright:      © 2025 Flecki Garnreiter
# License:        MIT License
#
# --- End of header ---

function Invoke-LogCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,

        [Parameter(Mandatory = $true)]
        [int]$RetentionDays
    )

    try {
        $limit = (Get-Date).AddDays(-$RetentionDays)
        Write-Log -Message "Performing log cleanup. Deleting logs older than $limit." -LogFilePath (Join-Path $LogPath "maintenance.log")
        
        Get-ChildItem -Path $LogPath -Recurse -Force | Where-Object { 
            !$_.PSIsContainer -and $_.CreationTime -lt $limit -and $_.Name -like "*.log" 
        } | ForEach-Object {
            Write-Log -Message "Deleting old log file: $($_.FullName)" -LogFilePath (Join-Path $LogPath "maintenance.log")
            Remove-Item -Path $_.FullName -Force
        }
    }
    catch {
        Write-Log -Message "Error during log cleanup: $_" -Level 'ERROR' -LogFilePath (Join-Path $LogPath "maintenance.log")
    }
}

Export-ModuleMember -Function Invoke-LogCleanup

# --- End of module --- v1.0.0 ; Regelwerk: v9.0.9 ---
