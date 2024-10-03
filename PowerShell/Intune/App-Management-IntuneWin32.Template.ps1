<#
# #################################################################################################################### #
# Filename: \PowerShell\Intune\App-Management-IntuneWin32.Template.ps1                                                 #
# Repository: Code-Templates                                                                                           #
# Created Date: Tuesday, October 1st 2024, 10:01:10 PM                                                                 #
# Last Modified: Thursday, October 3rd 2024, 9:21:43 PM                                                                #
# Original Author: Darnel Kumar                                                                                        #
# Author Github: https://github.com/Darnel-K                                                                           #
# Github Org: https://github.com/ABYSS-ORG-UK/                                                                         #
#                                                                                                                      #
# This code complies with: https://gist.github.com/Darnel-K/8badda0cabdabb15359350f7af911c90                           #
#                                                                                                                      #
# License: GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html                 #
# Copyright (c) 2024 Darnel Kumar                                                                                      #
#                                                                                                                      #
# This program is free software: you can redistribute it and/or modify                                                 #
# it under the terms of the GNU General Public License as published by                                                 #
# the Free Software Foundation, either version 3 of the License, or                                                    #
# (at your option) any later version.                                                                                  #
#                                                                                                                      #
# This program is distributed in the hope that it will be useful,                                                      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                                                       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                                        #
# GNU General Public License for more details.                                                                         #
# #################################################################################################################### #
#>

<#
.SYNOPSIS
    Install/Uninstall {App}
.DESCRIPTION
    App management script for installing, uninstalling & detecting {App}
.EXAMPLE
    & .\App-Management-IntuneWin32.Template.ps1
.Example
    & .\App-Management-IntuneWin32.Template.ps1 -Mode Install
.Example
    & .\App-Management-IntuneWin32.Template.ps1 -Mode Uninstall
.Example
    & .\App-Management-IntuneWin32.Template.ps1 -Mode Detect
#>

[CmdletBinding()]
Param (
    [Parameter()]
    [ValidateSet("Install", "Uninstall", "Detect")]
    [PSDefaultValue(Help = 'Defaults to detection mode')]
    [string[]]
    # Specifies which mode the script should run in. Install Mode, Uninstall Mode or Detection Mode.
    $Mode = "Detect",
    [Parameter()]
    [switch]
    # Bypass checks and force install/uninstall
    $Force = $false
)

#################################
#                               #
#   REQUIRED SCRIPT VARIABLES   #
#                               #
#################################

# DO NOT REMOVE THESE VARIABLES
# DO NOT LEAVE THESE VARIABLES BLANK

$APP_NAME = "" # Name of the software (Bitwarden, Python, Google Chrome)
$APP_VERSION = "0" # App version to be installed
$INSTALLER_PATH = "" # Path to installer executable file (exe, msi, ect)
$INSTALLER_EXECUTABLE = "" # Filename of the installer executable
$INSTALLER_ARGUMENTS = "" # Arguments for the installer executable to enable silent installation & other features
$INSTALL_DIRECTORY = "" # Folder path that the software is installed
$INSTALLED_EXECUTABLE = "" # Installed software executable
$UNINSTALLER_PATH = $INSTALL_DIRECTORY # Path to uninstaller executable. Default set to installer path
$UNINSTALLER_EXECUTABLE = "" # Filename of the uninstaller executable
$UNINSTALLER_ARGUMENTS = "" # Arguments for the uninstaller executable to enable silent uninstallation

################################################
#                                              #
#   DO NOT EDIT ANYTHING BELOW THIS MESSAGE!   #
#                                              #
################################################

# Script functions - DO NOT CHANGE!

function init {
    switch ($Mode) {
        'Install' {
            $CUSTOM_LOG.Information("Starting $SCRIPT_NAME in $Mode mode")
            installApp
        }
        'Uninstall' {
            $CUSTOM_LOG.Information("Starting $SCRIPT_NAME in $Mode mode")
            uninstallApp
        }
        'Detect' {
            $CUSTOM_LOG.Information("Starting $SCRIPT_NAME in $Mode mode")
            if ((detectAppInstallState) -and -not (checkRegKeyAppVersionMismath)) {
                Exit 0
            }
            else {
                Exit 1
            }
        }
        Default {
            $CUSTOM_LOG.Information("Starting $SCRIPT_NAME in $Mode mode")
            if ((detectAppInstallState) -and -not (checkRegKeyAppVersionMismath)) {
                Exit 0
            }
            else {
                Exit 1
            }
        }
    }
}

function installApp {
    if (-not (detectAppInstallState) -or $Force) {
        forceInstallApp
    }
    else {
        $CUSTOM_LOG.Information("$APP_NAME is already installed.")
        if (checkRegKeyAppVersionMismath) {
            $CUSTOM_LOG.Information("Will attempt to install version $APP_VERSION of $APP_NAME")
            forceInstallApp
        }
        Exit 0
    }
}

function forceInstallApp {
    $CUSTOM_LOG.Information("Attempting to install $APP_NAME, please wait")
    try {
        if ($IS_ADMIN) {
            Start-Process -FilePath "$FULL_INSTALLER_PATH" -Wait -WindowStyle Hidden -ArgumentList "$INSTALLER_ARGUMENTS" -Verb RunAs
        }
        else {
            Start-Process -FilePath "$FULL_INSTALLER_PATH" -Wait -WindowStyle Hidden -ArgumentList "$INSTALLER_ARGUMENTS"
        }
    }
    catch {
        $CUSTOM_LOG.Error("Unable to install $APP_NAME")
        $CUSTOM_LOG.Error($Error[0])
        Exit 1
    }
    if (detectAppInstallState) {
        $CUSTOM_LOG.Success("$APP_NAME has been installed successfully")
        setAllRegKeys
        Exit 0
    }
    else {
        $CUSTOM_LOG.Fail("Unable to install $APP_NAME")
        $CUSTOM_LOG.Error("An unknown error has occured")
        Exit 1
    }
}

function uninstallApp {
    if ((detectAppInstallState) -or $Force) {
        $CUSTOM_LOG.Information("Attempting to uninstall $APP_NAME, please wait")
        try {
            if ($IS_ADMIN) {
                Start-Process -FilePath "$FULL_UNINSTALLER_PATH" -Wait -WindowStyle Hidden -ArgumentList "$UNINSTALLER_ARGUMENTS" -Verb RunAs
            }
            else {
                Start-Process -FilePath "$FULL_UNINSTALLER_PATH" -Wait -WindowStyle Hidden -ArgumentList "$UNINSTALLER_ARGUMENTS"
            }
        }
        catch {
            $CUSTOM_LOG.Error("Unable to uninstall $APP_NAME")
            $CUSTOM_LOG.Error($Error[0])
            Exit 1
        }
        if (-not (detectAppInstallState)) {
            $CUSTOM_LOG.Success("$APP_NAME has been uninstalled successfully")
            removeRegKey
            Exit 0
        }
        else {
            $CUSTOM_LOG.Fail("Unable to uninstall $APP_NAME")
            $CUSTOM_LOG.Error("An unknown error has occured")
            Exit 1
        }
    }
    else {
        $CUSTOM_LOG.Information("$APP_NAME is already uninstalled.")
        Exit 0
    }
}

function detectAppInstallState {
    if (Test-Path "$FULL_INSTALLED_SOFTWARE_PATH" -PathType Leaf) {
        $CUSTOM_LOG.Information("'$APP_NAME' is installed on this device")
        return $true
    }
    else {
        $CUSTOM_LOG.Information("'$APP_NAME' is not installed on this device")
        return $false
    }
}

function setAllRegKeys {
    foreach ($i in ($REG_DATA | Sort-Object -Property Path)) {
        if (!(Test-Path -Path $i.Path)) {
            try {
                New-Item -Path $i.Path -Force -ErrorAction Stop | Out-Null
                $CUSTOM_LOG.Success("Created path: $($i.Path)")
            }
            catch {
                $CUSTOM_LOG.Fail("Failed to create registry path: $($i.Path)")
                $CUSTOM_LOG.Error($Error[0])
            }
        }
        if ($i.Key) {
            if ((Get-ItemProperty $i.Path).PSObject.Properties.Name -contains $i.Key) {
                try {
                    Set-ItemProperty -Path $i.Path -Name $i.Key -Value $i.Value -Force -ErrorAction Stop | Out-Null
                    $CUSTOM_LOG.Success("Successfully made the following registry edit:`n - Key: $($i.Path)`n - Property: $($i.Key)`n - Value: $($i.Value)`n - Type: $($i.Type)")
                }
                catch {
                    $CUSTOM_LOG.Fail("Failed to make the following registry edit:`n - Key: $($i.Path)`n - Property: $($i.Key)`n - Value: $($i.Value)`n - Type: $($i.Type)")
                    $CUSTOM_LOG.Error($Error[0])
                }
            }
            else {
                try {
                    New-ItemProperty -Path $i.Path -Name $i.Key -Value $i.Value -Type $i.Type -Force -ErrorAction Stop | Out-Null
                    $CUSTOM_LOG.Success("Created the following registry entry:`n - Key: $($i.Path)`n - Property: $($i.Key)`n - Value: $($i.Value)`n - Type: $($i.Type)")
                }
                catch {
                    $CUSTOM_LOG.Fail("Failed to make the following registry edit:`n - Key: $($i.Path)`n - Property: $($i.Key)`n - Value: $($i.Value)`n - Type: $($i.Type)")
                    $CUSTOM_LOG.Error($Error[0])
                }
            }
        }
    }
    $CUSTOM_LOG.Success("Completed registry update successfully.")
}

function removeRegKey {
    foreach ($i in ($REG_DATA | Sort-Object -Property Path, Key -Descending)) {
        if (Test-Path -Path $i.Path) {
            if ($i.Key) {
                try {
                    Remove-ItemProperty -Path $i.Path -Name $i.Key | Out-Null
                    $CUSTOM_LOG.Success("Removed registry Property:`n - Key: $($i.Path)`n - Property: $($i.Key)")
                }
                catch {
                    $CUSTOM_LOG.Fail("Failed to remove registy property: $($i.Key) at path: $($i.Path)")
                    $CUSTOM_LOG.Error($Error[0])
                }
            }
            else {
                try {
                    Remove-Item -Path $i.Path -Recurse -Force | Out-Null
                    $CUSTOM_LOG.Success("Removed registry Key:`n - Key: $($i.Path)")
                }
                catch {
                    $CUSTOM_LOG.Fail("Failed to remove registy path: $($i.Path)")
                    $CUSTOM_LOG.Error($Error[0])
                }
            }
        }
        else {
            $CUSTOM_LOG.Information("Registry Path '$($i.Path)' does not exist")
        }
    }
    $CUSTOM_LOG.Success("Completed registry update successfully.")
}

function checkRegKeyAppVersionMismath {
    $CUSTOM_LOG.Information("Checking application current version")
    if (Test-Path -Path $REG_KEY_FULL_PATH) {
        try {
            $installed_app_version = Get-ItemProperty -Path $REG_KEY_FULL_PATH -Name "ApplicationVersion" | Select-Object -ExpandProperty ApplicationVersion
            $CUSTOM_LOG.Information("Installed Version: $installed_app_version")
            $CUSTOM_LOG.Information("Packaged Version: $APP_VERSION")
            if ($APP_VERSION -ne $installed_app_version) {
                $CUSTOM_LOG.Information("Detected version mismatch between the installed application and the packaged version")
                return $true
            }
            else {
                $CUSTOM_LOG.Information("Detected identical version between the installed application and the packaged version")
                return $false
            }
        }
        catch {
            $CUSTOM_LOG.Fail("Unable to check installed app version. Registry keys likely don't exist. Assuming the packaged version is different.")
            $CUSTOM_LOG.Error($Error[0])
            return $true
        }
    }
    else {
        $CUSTOM_LOG.Fail("Unable to check installed app version. Registry keys likely don't exist. Assuming the packaged version is different.")
        return $true
    }
}

function checkRunIn64BitPowershell {
    if (($env:PROCESSOR_ARCHITECTURE -eq "x86") -or ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64")) {
        $CUSTOM_LOG.Warning("'$SCRIPT_NAME' is running in 32-bit (x86) mode")
        try {
            $CUSTOM_LOG.Information("Attempting to start $SCRIPT_NAME in 64-bit (x64) mode")
            if ($Force) {
                Start-Process -FilePath "$env:windir\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -Wait -NoNewWindow -ArgumentList "-File ""$PSCOMMANDPATH"" -Mode $Mode -Force"
            }
            else {
                Start-Process -FilePath "$env:windir\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -Wait -NoNewWindow -ArgumentList "-File ""$PSCOMMANDPATH"" -Mode $Mode"
            }
            Exit 0
        }
        catch {
            $CUSTOM_LOG.Error("Unable to start '$SCRIPT_NAME' in 64-bit (x64) mode")
            $CUSTOM_LOG.Error($Error[0])
            Exit 1
        }
        Exit 1
    }
    else {
        $CUSTOM_LOG.Information("'$SCRIPT_NAME' is running in 64-bit (x64) mode")
    }
}

# Pre-defined Variables - DO NOT CHANGE!
$SCRIPT_NAME = ".Intune.Win32App.$($APP_NAME.Replace(' ',''))"
$FULL_INSTALLER_PATH = "$INSTALLER_PATH\$INSTALLER_EXECUTABLE"
$FULL_UNINSTALLER_PATH = "$UNINSTALLER_PATH\$UNINSTALLER_EXECUTABLE"
$FULL_INSTALLED_SOFTWARE_PATH = "$INSTALL_DIRECTORY\$INSTALLED_EXECUTABLE"
[Boolean]$IS_SYSTEM = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).Identities.IsSystem
[Boolean]$IS_ADMIN = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[String]$EXEC_USER = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).Identities.Name
[Int]$PID = [System.Diagnostics.Process]::GetCurrentProcess().Id

# Script & Terminal Preferences - DO NOT CHANGE!
$ProgressPreference = "Continue"
$InformationPreference = "Continue"
$DebugPreference = "SilentlyContinue"
$ErrorActionPreference = "Continue"
$VerbosePreference = "SilentlyContinue"
$WarningPreference = "Continue"
$host.ui.RawUI.WindowTitle = $SCRIPT_NAME

# Create new instance of CustomLog class and initialise Event Log - DO NOT CHANGE!
$CUSTOM_LOG = [CustomLog]::new($SCRIPT_NAME)
$CUSTOM_LOG.InitEventLog()

# Console Signature - DO NOT CHANGE!
$SCRIPT_FILENAME = $MyInvocation.MyCommand.Name
function sig {
    $len = @(($SCRIPT_NAME.Length + 13), ($SCRIPT_FILENAME.Length + 10), 20, 42, 29, 40, 63, 62, 61, 44)
    $len_max = ($len | Measure-Object -Maximum).Maximum
    Write-Host "`t####$('#'*$len_max)####`n`t#   $(' '*$len_max)   #`n`t#   Script Name: $($SCRIPT_NAME)$(' '*($len_max-$len[0]))   #`n`t#   Filename: $($SCRIPT_FILENAME)$(' '*($len_max-$len[1]))   #`n`t#   $(' '*$len_max)   #`n`t#   Author: Darnel Kumar$(' '*($len_max-$len[2]))   #`n`t#   Author GitHub: https://github.com/Darnel-K$(' '*($len_max-$len[3]))   #`n`t#   Copyright $([char]0x00A9) $(Get-Date -Format  'yyyy') Darnel Kumar$(' '*($len_max-$len[4]))   #`n`t#   $(' '*$len_max)   #`n`t#   $('-'*$len_max)   #`n`t#   $(' '*$len_max)   #`n`t#   License: GNU General Public License v3.0$(' '*($len_max-$len[5]))   #`n`t#   $(' '*$len_max)   #`n`t#   This program is distributed in the hope that it will be useful,$(' '*($len_max-$len[6]))   #`n`t#   but WITHOUT ANY WARRANTY; without even the implied warranty of$(' '*($len_max-$len[7]))   #`n`t#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the$(' '*($len_max-$len[8]))   #`n`t#   GNU General Public License for more details.$(' '*($len_max-$len[9]))   #`n`t#   $(' '*$len_max)   #`n`t####$('#'*$len_max)####`n" -ForegroundColor Green
}

# Set registry variables, paths & keys - DO NOT CHANGE!
if ($IS_SYSTEM) { $REG_KEY_ROOT = 'HKLM:\' } else { $REG_KEY_ROOT = 'HKCU:\' }
$REG_KEY_PATH = "Software\ABYSS.ORG.UK\MDM-APP-MANAGEMENT\$SCRIPT_NAME"
$REG_KEY_FULL_PATH = "$REG_KEY_ROOT$REG_KEY_PATH"
$REG_DATA = @(
    [PSCustomObject]@{
        Path = "$REG_KEY_FULL_PATH"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ScriptName"
        Value = "$SCRIPT_NAME"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ApplicationName"
        Value = "$APP_NAME"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ApplicationVersion"
        Value = "$APP_VERSION"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ScriptFilename"
        Value = "$SCRIPT_FILENAME"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "TargetUserIsAdmin"
        Value = "$IS_ADMIN"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ExecUserIsSystem"
        Value = "$IS_SYSTEM"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ExecUser"
        Value = "$EXEC_USER"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "InstallDir"
        Value = "$INSTALL_DIRECTORY"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "InstallCommand"
        Value = "$FULL_INSTALLER_PATH $INSTALLER_ARGUMENTS"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "UninstallCommand"
        Value = "$FULL_UNINSTALLER_PATH $UNINSTALLER_ARGUMENTS"
        Type  = "STRING"
    }
    [PSCustomObject]@{
        Path  = "$REG_KEY_FULL_PATH"
        Key   = "ScriptRunDateTime"
        Value = "$(Get-Date -Format 'yyyy-MM-dd HH:mm K')"
        Type  = "STRING"
    }
)

# Define CustomLog class - DO NOT CHANGE!
class CustomLog {
    [string] $log_name
    [string] $log_source
    hidden [Boolean] $event_log_init

    CustomLog() {
        $this.log_name = "ABYSS.ORG.UK"
        $this.event_log_init = $false
        $this.log_source = "Default"
    }

    CustomLog([String]$log_source) {
        $this.log_name = "ABYSS.ORG.UK"
        $this.event_log_init = $false
        $this.log_source = $log_source
    }

    CustomLog([String]$log_name, [String]$log_source) {
        $this.log_name = $log_name
        $this.event_log_init = $false
        $this.log_source = $log_source
    }

    [void] InitEventLog() {
        if (-not $this.CheckEventLogExists()) {
            if (-not $this.CreateEventLog()) {
                Write-Warning "Unable to initialise event log '$($this.log_name)' with source '$($this.log_source)', falling back to event log 'Application' with source 'Application'"
                $this.log_name, $this.log_source = "Application", "Application"
                $this.event_log_init = $true
            }
            else {
                $this.event_log_init = $true
                $this.Success("Log initialised using event log '$($this.log_name)' with source '$($this.log_source)'")
            }
        }
        else {
            $this.event_log_init = $true
            Write-Verbose "Event log '$($this.log_name)' with source '$($this.log_source)' already exists, using existing event log"
        }
    }

    [Boolean] CheckEventLogInit($event_log_enabled_per_message = $this.event_log_init) {
        if ($this.event_log_init -and $event_log_enabled_per_message) {
            return $true
        }
        elseif ($this.event_log_init -and -not $event_log_enabled_per_message) {
            return $false
        }
        elseif (-not $this.event_log_init -and -not $event_log_enabled_per_message) {
            return $false
        }
        else {
            Write-Warning "Cannot write to event log!"
            Write-Warning "Event log not initialised, please initialise logging system!"
            return $false
        }
    }

    [Boolean] CheckEventLogExists() {
        Write-Verbose "Checking if event log '$($this.log_name)' & source '$($this.log_source)' exists"
        try {
            if (-not ([System.Diagnostics.EventLog]::Exists($this.log_name)) -or -not ([System.Diagnostics.EventLog]::SourceExists($this.log_source))) {
                Write-Verbose "Event log '$($this.log_name)' or source '$($this.log_source)' does not exist"
                return $false
            }
            else {
                return $true
            }
        }
        catch {
            Write-Verbose "Unable to check if event log '$($this.log_name)' or source '$($this.log_source)' exists"
            Write-Debug $Error[0]
            return $false
        }

    }

    [Boolean] CreateEventLog() {
        try {
            Write-Verbose "Attempting to create event log '$($this.log_name)' & source '$($this.log_source)'"
            New-EventLog -LogName $this.log_name -Source $this.log_source -ErrorAction Stop
            if ($this.CheckEventLogExists()) {
                return $true
            }
            else {
                throw "Unable to create event log '$($this.log_name)' or source '$($this.log_source)'"
            }
        }
        catch {
            Write-Verbose "Unable to create event log '$($this.log_name)' or source '$($this.log_source)'"
            Write-Debug $Error[0]
            return $false
        }
    }

    [void] Success([string]$msg) {
        $this.Success($msg, 0, $this.event_log_init)
    }
    [void] Success([string]$msg, [Boolean]$event_log_enabled) {
        $this.Success($msg, 0, $event_log_enabled)
    }
    [void] Success([string]$msg, [int]$event_id) {
        $this.Success($msg, $event_id, $this.event_log_init)
    }
    [void] Success([string]$msg, [int]$event_id, [Boolean]$event_log_enabled) {
        if ($this.CheckEventLogInit($event_log_enabled)) {
            Write-EventLog -LogName $this.log_name -Source $this.log_source -EntryType SuccessAudit -Message $msg -EventId $event_id
        }
        Write-Host "SUCCESS: $msg" -ForegroundColor Green
    }

    [void] Fail([string]$msg) {
        $this.Fail($msg, 0, $this.event_log_init)
    }
    [void] Fail([string]$msg, [Boolean]$event_log_enabled) {
        $this.Fail($msg, 0, $event_log_enabled)
    }
    [void] Fail([string]$msg, [int]$event_id) {
        $this.Fail($msg, $event_id, $this.event_log_init)
    }
    [void] Fail([string]$msg, [int]$event_id, [Boolean]$event_log_enabled) {
        if ($this.CheckEventLogInit($event_log_enabled)) {
            Write-EventLog -LogName $this.log_name -Source $this.log_source -EntryType FailureAudit -Message $msg -EventId $event_id
        }
        Write-Host "FAILURE: $msg" -ForegroundColor Red
    }

    [void] Information([string]$msg) {
        $this.Information($msg, 0, $this.event_log_init)
    }
    [void] Information([string]$msg, [Boolean]$event_log_enabled) {
        $this.Information($msg, 0, $event_log_enabled)
    }
    [void] Information([string]$msg, [int]$event_id) {
        $this.Information($msg, $event_id, $this.event_log_init)
    }
    [void] Information([string]$msg, [int]$event_id, [Boolean]$event_log_enabled) {
        if ($this.CheckEventLogInit($event_log_enabled)) {
            Write-EventLog -LogName $this.log_name -Source $this.log_source -EntryType Information -Message $msg -EventId $event_id
        }
        Write-Information "INFO: $msg" -InformationAction Continue
    }

    [void] Warning([string]$msg) {
        $this.Warning($msg, 0, $this.event_log_init)
    }
    [void] Warning([string]$msg, [Boolean]$event_log_enabled) {
        $this.Warning($msg, 0, $event_log_enabled)
    }
    [void] Warning([string]$msg, [int]$event_id) {
        $this.Warning($msg, $event_id, $this.event_log_init)
    }
    [void] Warning([string]$msg, [int]$event_id, [Boolean]$event_log_enabled) {
        if ($this.CheckEventLogInit($event_log_enabled)) {
            Write-EventLog -LogName $this.log_name -Source $this.log_source -EntryType Warning -Message $msg -EventId $event_id
        }
        Write-Warning $msg -WarningAction Continue
    }

    [void] Error([string]$msg) {
        $this.Error($msg, 0, $this.event_log_init)
    }
    [void] Error([string]$msg, [Boolean]$event_log_enabled) {
        $this.Error($msg, 0, $event_log_enabled)
    }
    [void] Error([string]$msg, [int]$event_id) {
        $this.Error($msg, $event_id, $this.event_log_init)
    }
    [void] Error([string]$msg, [int]$event_id, [Boolean]$event_log_enabled) {
        if ($this.CheckEventLogInit($event_log_enabled)) {
            Write-EventLog -LogName $this.log_name -Source $this.log_source -EntryType Error -Message $msg -EventId $event_id
        }
        Write-Error "ERROR: $msg" -ErrorAction Continue
    }

}

# Clear console & display signature before script initialisation
Clear-Host
sig
checkRunIn64BitPowershell
init
