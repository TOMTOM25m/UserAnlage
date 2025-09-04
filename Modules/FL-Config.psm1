# --- FL-Config.psm1 ---
#
# Modul für Konfigurations-Management
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

function Get-ScriptConfiguration {
    [CmdletBinding()]
    param(
        [string]$ScriptDirectory
    )

    $configPath = Join-Path -Path $ScriptDirectory -ChildPath "Config\Config-AD-User_Anlage.ps1.json"
    $defaultConfig = @{
        ScriptVersion   = "v7.0.0"
        RulebookVersion = "v9.0.9"
        Language        = "de-DE"
        Environment     = "DEV"
        WhatIf          = $false
        Mail            = @{
            Enabled    = $true
            To         = "Win-Admin@meduniwien.ac.at"
            From       = "$env:COMPUTERNAME@meduniwien.ac.at"
            SmtpServer = "smtpi.meduniwien.ac.at"
            Port       = 25
        }
        Paths           = @{
            HomeBasePath    = "\\filesrv\home$"
            ProfileBasePath = "\\filesrv\profiles$"
        }
    }

    if (-not (Test-Path $configPath)) {
        Write-Warning "Configuration file not found. Using default settings. Path: $configPath"
        $config = $defaultConfig | ConvertTo-Json -Depth 5
        New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
        $config | Out-File -FilePath $configPath -Encoding utf8
    }

    $config = Get-Content -Path $configPath -Encoding utf8 | ConvertFrom-Json

    # Load Localization
    $langPath = Join-Path -Path $ScriptDirectory -ChildPath "Config\$($config.Language).json"
    if (-not (Test-Path $langPath)) {
        Write-Warning "Language file not found for '$($config.Language)'. Falling back to 'en-US'."
        $config.Language = "en-US"
        $langPath = Join-Path -Path $ScriptDirectory -ChildPath "Config\en-US.json"
    }
    
    $localization = Get-Content -Path $langPath -Encoding utf8 | ConvertFrom-Json

    return @{
        Config       = $config
        Localization = $localization
    }
}

Export-ModuleMember -Function Get-ScriptConfiguration

# --- End of module --- v1.0.0 ; Regelwerk: v9.0.9 ---
