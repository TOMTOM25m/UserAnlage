# --- FL-Logging.psm1 ---
#
# Modul für Logging-Funktionen gemäß MUW-Regelwerk.
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

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($NoNewLine) {
        Write-Host $logMessage -NoNewline
    } else {
        Write-Host $logMessage
    }

    if ($Global:sLogFile) {
        try {
            Add-Content -Path $Global:sLogFile -Value $logMessage -Encoding utf8
        }
        catch {
            Write-Host "[$timestamp] [ERROR] Failed to write to log file: $($Global:sLogFile). Error: $($_.Exception.Message)"
        }
    }
}

# Legacy logging functions for compatibility
function WriteLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message, 
        [Parameter(Mandatory=$false)][Switch]$N
    ) 
    if ($N) {
        Write-Log -Message $Message -NoNewLine
    } else {
        Write-Log -Message $Message
    }
}

function WriteDLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Message, 
        [Parameter(Mandatory=$false)][Switch]$N
    ) 
    if ($N) {
        Write-Log -Message $Message -Level 'DEBUG' -NoNewLine
    } else {
        Write-Log -Message $Message -Level 'DEBUG'
    }
}

Export-ModuleMember -Function Write-Log, WriteLog, WriteDLog

# --- End of module --- v1.0.0 ; Regelwerk: v9.0.9 ---
