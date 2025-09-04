# --- FL-Gui.psm1 ---
#
# Modul für GUI-Funktionen (WPF)
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

function Show-ADUserWorkGui {
    [CmdletBinding()]
    param(
        [hashtable]$Localization,
        [hashtable]$Config
    )

    try {
        # XAML für die WorkGUI
        $xaml = @"
<Window xmlns="https://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="https://schemas.microsoft.com/winfx/2006/xaml"
        Title="AD User Creation" Width="600" Height="550"
        WindowStartupLocation="CenterScreen"
        Background="#f0f0f0">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Kalercherl Search Section -->
        <GroupBox Header="Kalercherl Search" Grid.Row="0" Margin="5" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Label Content="Search by Name:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtSearchName" Grid.Row="0" Grid.Column="1" Margin="5"/>
                <Button x:Name="btnSearchName" Content="Search" Grid.Row="0" Grid.Column="2" Width="80" Margin="5"/>

                <Label Content="Search by MUWID:" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtSearchMuwid" Grid.Row="1" Grid.Column="1" Margin="5"/>
                <Button x:Name="btnSearchMuwid" Content="Search" Grid.Row="1" Grid.Column="2" Width="80" Margin="5"/>
            </Grid>
        </GroupBox>

        <!-- User Data Section -->
        <GroupBox Header="User Data" Grid.Row="1" Margin="5" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Label Content="MUWID:" Grid.Row="0" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtMuwid" Grid.Row="0" Grid.Column="1" Margin="5"/>

                <Label Content="First Name:" Grid.Row="1" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtVorname" Grid.Row="1" Grid.Column="1" Margin="5"/>

                <Label Content="Last Name:" Grid.Row="2" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtNachname" Grid.Row="2" Grid.Column="1" Margin="5"/>

                <Label Content="Login Name Type:" Grid.Row="3" Grid.Column="0" VerticalAlignment="Center"/>
                <ComboBox x:Name="cmbIdOrUser" Grid.Row="3" Grid.Column="1" Margin="5">
                    <ComboBoxItem Content="ID (MUWID)" IsSelected="True"/>
                    <ComboBoxItem Content="User (DisplayName)"/>
                </ComboBox>

                <Label Content="Password:" Grid.Row="4" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtPassword" Grid.Row="4" Grid.Column="1" Margin="5" Text="med123%"/>

                <Label Content="Copy Permissions from (MUWID):" Grid.Row="5" Grid.Column="0" VerticalAlignment="Center"/>
                <TextBox x:Name="txtCopyId" Grid.Row="5" Grid.Column="1" Margin="5"/>
            </Grid>
        </GroupBox>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="5">
            <Button x:Name="btnCreateUser" Content="Create User" Width="100" Margin="5" Background="#111d4e" Foreground="White"/>
            <Button x:Name="btnCancel" Content="Cancel" Width="100" Margin="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

        # Erstelle WPF-Objekte
        $reader = New-Object System.Xml.XmlNodeReader -ArgumentList ([System.Xml.XmlDocument]@{ InnerXml = $xaml.Replace('$($', '$$(') })
        $window = [Windows.Markup.XamlReader]::Load($reader)
        $controls = @{}
        $xaml.SelectNodes("//*[@*[contains(., 'x:Name')]]") | ForEach-Object { $controls[$_.Name] = $window.FindName($_.Name) }

        # Event Handler
        $controls.btnSearchName.add_Click({
            param($sender, $e)
            $name = $controls.txtSearchName.Text
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                $nameParts = $name.Split(' ', 2)
                $vorname = $nameParts[0]
                $nachname = if ($nameParts.Count -gt 1) { $nameParts[1] } else { '' }
                $userData = Get-UserDataFromKalercherl -Vorname $vorname -Nachname $nachname
                if ($userData) {
                    $controls.txtMuwid.Text = $userData.MUWID
                    $controls.txtVorname.Text = $userData.Vorname
                    $controls.txtNachname.Text = $userData.Nachname
                } else {
                    [System.Windows.MessageBox]::Show("User not found in Kalercherl.", "Search Result", "OK", "Information")
                }
            }
        })

        $controls.btnSearchMuwid.add_Click({
            param($sender, $e)
            $muwid = $controls.txtSearchMuwid.Text
            if (-not [string]::IsNullOrWhiteSpace($muwid)) {
                $userData = Get-UserDataFromKalercherl -MUWID $muwid
                if ($userData) {
                    $controls.txtMuwid.Text = $userData.MUWID
                    $controls.txtVorname.Text = $userData.Vorname
                    $controls.txtNachname.Text = $userData.Nachname
                } else {
                    [System.Windows.MessageBox]::Show("User not found in Kalercherl.", "Search Result", "OK", "Information")
                }
            }
        })

        $controls.btnCreateUser.add_Click({
            param($sender, $e)
            $window.DialogResult = $true
            $window.Close()
        })

        $controls.btnCancel.add_Click({
            param($sender, $e)
            $window.DialogResult = $false
            $window.Close()
        })

        # Zeige das Fenster an
        if ($window.ShowDialog()) {
            return @{
                MUWID = $controls.txtMuwid.Text
                Vorname = $controls.txtVorname.Text
                Nachname = $controls.txtNachname.Text
                ID_or_User = $controls.cmbIdOrUser.Text.Split(' ')[0]
                Password = $controls.txtPassword.Text
                CopyFromID = $controls.txtCopyId.Text
            }
        } else {
            return $null
        }

    } catch {
        Write-Error "Failed to show AD User Work GUI. Error: $_"
        return $null
    }
}

Export-ModuleMember -Function Show-ADUserWorkGui

# --- End of module --- v1.0.0 ; Regelwerk: v9.0.9 ---
