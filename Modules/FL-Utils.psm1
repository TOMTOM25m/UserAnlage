# --- FL-Utils.psm1 ---
#
# Modul für allgemeine Hilfsfunktionen
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

#region ####################### [Kalercherl & Data Functions] ##############################
Function Get-KalercherrlUserByName {
    <#
    .SYNOPSIS
        Searches for user data in Kalercherl by last name and first name (Option 1)
    .PARAMETER Nachname
        Last name of the user to search for
    .PARAMETER Vorname
        First name of the user to search for
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Nachname,
        
        [Parameter(Mandatory = $true)]
        [string]$Vorname
    )
    
    try {
        Write-Log -Message "Kalercherl search by name: $Vorname $Nachname" -Level "DEBUG"
        
        # Kalercherl URL for name-based search (Option 1)
        $kalercherrlUrl = "https://kamel.meduniwien.ac.at/hilfetisch/kalercherl.html"
        
        # Build search parameters for name-based search
        $searchParams = @{
            'nachname' = $Nachname
            'vorname' = $Vorname
            'submit' = 'Suchen'
        }
        
        # Execute web request to Kalercherl
        $response = Invoke-WebRequest -Uri $kalercherrlUrl -Method POST -Body $searchParams -UseBasicParsing
        
        # Parse the response for user data
        $userData = Parse-KalercherrlResponse -ResponseContent $response.Content
        
        Write-Log -Message "Kalercherl search completed for: $Vorname $Nachname" -Level "DEBUG"
        return $userData
        
    } catch {
        Write-Log -Message "Error in Kalercherl name search: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

Function Get-KalercherrlUserByMUWID {
    <#
    .SYNOPSIS
        Searches for user data in Kalercherl by MUWID (Option 2)
    .PARAMETER MUWID
        MedUni Wien ID to search for
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MUWID
    )
    
    try {
        Write-Log -Message "Kalercherl search by MUWID: $MUWID" -Level "DEBUG"
        
        # First try: Direct MUWID search (Option 2)
        $kalercherrlUrl = "https://kamel.meduniwien.ac.at/hilfetisch/kalercherl.html"
        
        $searchParams = @{
            'userid' = $MUWID.ToLower()
            'submit' = 'Suchen'
        }
        
        $response = Invoke-WebRequest -Uri $kalercherrlUrl -Method POST -Body $searchParams -UseBasicParsing
        $userData = Parse-KalercherrlResponse -ResponseContent $response.Content
        
        # If direct search fails, try OpenLDAP search
        if ($null -eq $userData) {
            Write-Log -Message "Direct Kalercherl search failed, trying OpenLDAP for MUWID: $MUWID" -Level "DEBUG"
            $userData = Get-LDAP -Filter "(uid=$($MUWID.ToLower()))"
            
            if ($userData) {
                # Convert LDAP result to consistent format
                $userData = ConvertFrom-LDAPToKalercherrlFormat -LDAPData $userData
            }
        }
        
        Write-Log -Message "Kalercherl/LDAP search completed for MUWID: $MUWID" -Level "DEBUG"
        return $userData
        
    } catch {
        Write-Log -Message "Error in Kalercherl MUWID search: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

Function Parse-KalercherrlResponse {
    <#
    .SYNOPSIS
        Parses the HTML response from Kalercherl and extracts user data
    .PARAMETER ResponseContent
        HTML content from Kalercherl response
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent
    )
    
    try {
        # Parse HTML response for user data
        # This is a simplified parser - adjust based on actual Kalercherl HTML structure
        
        if ($ResponseContent -match 'Keine Einträge gefunden' -or $ResponseContent -match 'No entries found') {
            Write-Log -Message "No entries found in Kalercherl response" -Level "WARNING"
            return $null
        }
        
        # Extract user information from HTML
        # Note: This needs to be adjusted based on the actual HTML structure of Kalercherl
        $userData = [PSCustomObject]@{
            MUWID = $null
            Vorname = $null
            Nachname = $null
            DisplayName = $null
            EMail = $null
            DepartmentNumber = $null
            DistinguishedName = $null
        }
        
        # HTML parsing logic would go here
        # For now, return null to indicate web parsing is needed
        Write-Log -Message "Kalercherl HTML parsing not yet implemented - use LDAP fallback" -Level "WARNING"
        return $null
        
    } catch {
        Write-Log -Message "Error parsing Kalercherl response: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

Function ConvertFrom-LDAPToKalercherrlFormat {
    <#
    .SYNOPSIS
        Converts LDAP search results to consistent Kalercherl format
    .PARAMETER LDAPData
        LDAP search result data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $LDAPData
    )
    
    try {
        if ($null -eq $LDAPData -or $LDAPData.Count -eq 0) {
            return $null
        }
        
        # Take first result if multiple entries
        $entry = $LDAPData[0]
        
        $userData = [PSCustomObject]@{
            MUWID = $entry.uid
            Vorname = $entry.givenname
            Nachname = $entry.sn
            DisplayName = $entry.displayname
            EMail = $entry.mail
            DepartmentNumber = $entry.departmentnumber
            DistinguishedName = $entry.distinguishedname
        }
        
        Write-Log -Message "Converted LDAP data to Kalercherl format for: $($userData.MUWID)" -Level "DEBUG"
        return $userData
        
    } catch {
        Write-Log -Message "Error converting LDAP data: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

Function Get-UserDataFromKalercherl {
    <#
    .SYNOPSIS
        Main function to get user data from Kalercherl using various search methods
    .PARAMETER MUWID
        MedUni Wien ID (optional)
    .PARAMETER Vorname
        First name (optional)
    .PARAMETER Nachname
        Last name (optional)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$MUWID,
        
        [Parameter(Mandatory = $false)]
        [string]$Vorname,
        
        [Parameter(Mandatory = $false)]
        [string]$Nachname
    )
    
    $userData = $null
    
    try {
        # Strategy 1: If MUWID is provided, search by MUWID
        if (-not [string]::IsNullOrWhiteSpace($MUWID)) {
            Write-Log -Message "Searching Kalercherl by MUWID: $MUWID"
            $userData = Get-KalercherrlUserByMUWID -MUWID $MUWID
        }
        
        # Strategy 2: If no result and names provided, search by name
        if ($null -eq $userData -and -not [string]::IsNullOrWhiteSpace($Vorname) -and -not [string]::IsNullOrWhiteSpace($Nachname)) {
            Write-Log -Message "Searching Kalercherl by name: $Vorname $Nachname"
            $userData = Get-KalercherrlUserByName -Nachname $Nachname -Vorname $Vorname
        }
        
        # Strategy 3: Fallback to direct LDAP search
        if ($null -eq $userData -and -not [string]::IsNullOrWhiteSpace($MUWID)) {
            Write-Log -Message "Fallback: Direct LDAP search for MUWID: $MUWID"
            $ldapResult = Get-LDAP -Filter "(uid=$($MUWID.ToLower()))"
            if ($ldapResult) {
                $userData = ConvertFrom-LDAPToKalercherrlFormat -LDAPData $ldapResult
            }
        }
        
        if ($userData) {
            Write-Log -Message "User data found: $($userData.MUWID) - $($userData.Vorname) $($userData.Nachname)"
        } else {
            Write-Log -Message "No user data found in Kalercherl or LDAP" -Level "WARNING"
        }
        
        return $userData
        
    } catch {
        Write-Log -Message "Error in Kalercherl user data retrieval: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}
#endregion

#region ####################### [Excel and File Functions] ############################## 
Function Get-LDAP {
    [CmdletBinding()]
    Param (
        [string]$Filter,
        [string]$LDAPServer = 'ldap.meduniwien.ac.at',
        [int]$LDAPPort = 389,
        [string]$baseDN = 'ou=people,o=meduniwien,c=at',
        [bool]$SSL = $false
    )

    $TitlecaseValues = 'dn', 'displayname', 'givenname', 'sn', 'departmentnumber', 'edupersonorgdn', 'mail', 'muwgender', 'uid'
    $UppercaseValues = '*'
    $IgnoreValues = 'pgp', 'objectclass'

    [System.Reflection.Assembly]::LoadWithPartialName('System.DirectoryServices.Protocols') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Net') | Out-Null

    $c = New-Object System.DirectoryServices.Protocols.LdapConnection "$($LDAPServer):$($LDAPPort)"
    $c.SessionOptions.SecureSocketLayer = $SSL;
    $c.AuthType = [System.DirectoryServices.Protocols.AuthType]::Anonymous

    $scope = [System.DirectoryServices.Protocols.SearchScope]::Subtree
    $attrlist = , '*'
    $r = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $baseDN, $Filter, $scope, $attrlist
    $re = $c.SendRequest($r);

    If ($re.Entries.Count -eq 0) {
        return $null
    } else {
        $output = @(0) * ($Re.Entries).count
        $i = 0

        foreach ($item in $Re.Entries) {
            $baseItem = [ordered]@{ }
            $baseItem.distinguishedname = $item.DistinguishedName

            foreach ($attribute in $item.attributes.GetEnumerator()) {
                $attribname = $attribute.Key
                $attribvalue = $attribute.Value.Item(0)

                If ($IgnoreValues -notcontains $attribname) {
                    If ($TitlecaseValues -contains $attribname) {
                        $attribvalue = (Get-Culture).textinfo.totitlecase($attribvalue.toLower())
                    } ElseIF ($UppercaseValues -contains $attribname) {
                        $attribvalue = $attribvalue.ToUpper()
                    } 

                    $baseItem.$($AttribName) = $AttribValue
                }
            }

            $output[$i] = New-Object -TypeName psobject -Property $baseItem
            $i += 1

        }
        $c.Dispose();
        return $output

    }

}

Function New-AD_User {
    param (
        [Parameter(Mandatory = $True)]
        [hashtable]$UserData,
        [Parameter(Mandatory = $True)]
        [string]$CopyID,
        [Parameter(Mandatory = $True)]
        [string]$Password
    )
    
    $dnsroot = (Get-ADDomain).DNSRoot
    $dc = (Get-ADDomainController -Discover -Domain $dnsroot).Hostname

    $Secure_String_Pwd = ConvertTo-SecureString $Password -AsPlainText -Force
    $UPN = ($UserData.MUWID.ToLower()) + '@' + $dnsroot
    $DisplayName = $UserData.Vorname + ' ' + $UserData.Nachname.ToUpper()
    
    $TemplateUser = Get-ADUser -Identity $CopyID -Server $dc
    if (-not $TemplateUser) {
        Write-Log -Message "Template user '$CopyID' not found." -Level 'ERROR'
        return
    }

    $ou = $TemplateUser.DistinguishedName.SubString($TemplateUser.DistinguishedName.IndexOf('OU='))

    $userParams = @{
        Name                = $DisplayName
        UserPrincipalName   = $UPN
        GivenName           = $UserData.Vorname
        Surname             = $UserData.Nachname.ToUpper()
        DisplayName         = $DisplayName
        Instance            = $TemplateUser
        AccountPassword     = $Secure_String_Pwd
        SamAccountName      = $UserData.MUWID.ToLower()
        Enabled             = $true
        Server              = $dc
        Path                = $ou
        ChangePasswordAtLogon = $true
    }

    New-ADUser @userParams

    Start-Sleep -Seconds 5
    $NewADuser = Get-ADUser $UserData.MUWID -Properties * -Server $DC
    
    # Copy attributes and group memberships
    Set-ADUser -Identity $NewADuser -Company $TemplateUser.Company -Country $TemplateUser.Country -Department $TemplateUser.Department -Server $DC
    Get-ADUser -Identity $TemplateUser -Properties memberof -Server $DC | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $NewADuser -Server $DC
    
    # Create Home and Profile Paths
    $homePath = Join-Path -Path $Global:Config.Paths.HomeBasePath -ChildPath $NewADuser.SamAccountName
    $profilePath = Join-Path -Path $Global:Config.Paths.ProfileBasePath -ChildPath ($NewADuser.SamAccountName + ".V6")
    
    New-PathWithPermission -Path $homePath -User $NewADuser.SamAccountName
    New-PathWithPermission -Path $profilePath -User $NewADuser.SamAccountName

    Set-ADUser -Identity $NewADuser -HomeDirectory $homePath -HomeDrive 'H:' -ProfilePath $profilePath
}

Function New-PathWithPermission {
    param(
        [Parameter(Mandatory = $True)]
        $path,
        [Parameter(Mandatory = $True)]
        $User
    )

    if (Test-Path $Path) {
        Write-Log -Message "The folder $Path already exists. No action taken"
    } else {
        New-Item -Path $Path -ItemType Directory | Out-Null
        Start-Sleep 1
        Add-NTFSAccess -Path $Path -Account $User -AccessRights FullControl -AccessType Allow -AppliesTo ThisFolderSubfoldersAndFiles
        if (Test-Path $Path) {
            Write-Log -Message "The folder $Path has been created."
        } else {
            Write-Log -Message "The folder $Path has NOT been created." -Level 'ERROR'
        }
    }
}

#endregion

function Send-MailNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$MailConfig,

        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Body
    )

    if (-not $MailConfig.Enabled) {
        Write-Log -Message "Mail notifications are disabled in the configuration."
        return
    }

    $smtpClient = New-Object System.Net.Mail.SmtpClient($MailConfig.SmtpServer, $MailConfig.Port)
    $mailMessage = New-Object System.Net.Mail.MailMessage($MailConfig.From, $MailConfig.To, $Subject, $Body)
    
    try {
        $smtpClient.Send($mailMessage)
        Write-Log -Message "Mail notification sent successfully to $($MailConfig.To)."
    } catch {
        Write-Log -Message "Failed to send mail notification. Error: $_" -Level 'ERROR'
    }
}

Export-ModuleMember -Function Get-KalercherrlUserByName, Get-KalercherrlUserByMUWID, Get-UserDataFromKalercherl, Get-LDAP, New-AD_User, New-PathWithPermission, Send-MailNotification

# --- End of module --- v1.0.0 ; Regelwerk: v9.0.9 ---
