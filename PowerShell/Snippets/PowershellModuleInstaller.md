# Powershell Module Installer

Checks to see if the modules defined in `$PS_MODULES` are installed and installs them automatically if not.

## Required Variables

```powershell
$PS_MODULES = @("Module1","Module2")
```

## Functions

To run call `installPsModules` at the beginning of your script

```powershell
function installNuGetPackageProvider {
    $CUSTOM_LOG.Information("Checking if NuGet package provider is installed")
    if ((Get-PackageProvider -Name NuGet)) {
        $CUSTOM_LOG.Information("NuGet package provider is already installed")
    }
    else {
        $CUSTOM_LOG.Information("NuGet package provider is not installed")
        $CUSTOM_LOG.Information("Attempting to install NuGet package provider")
        try {
            Install-PackageProvider -Name NuGet -Scope CurrentUser -Confirm:$false -Force:$true -ForceBootstrap:$true
        }
        catch {
            $CUSTOM_LOG.Error("Unable to install NuGet package provider")
            $CUSTOM_LOG.Error($Error[0])
            Exit 1
        }
        if ((Get-PackageProvider -Name NuGet)) {
            $CUSTOM_LOG.Success("NuGet package provider is installed")
        }
        else {
            $CUSTOM_LOG.Fail("NuGet package provider is not installed")
            $CUSTOM_LOG.Error("An unknown error occured")
            Exit 1
        }
    }
}
function installPsModules {
    installNuGetPackageProvider
    $CUSTOM_LOG.Information("Checking if all required PowerShell modules are installed")
    foreach ($module in $PS_MODULES) {
        $CUSTOM_LOG.Information("Checking if PowerShell module '$module' is installed")
        if ((Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
            $CUSTOM_LOG.Information("Module '$module' is already installed")
            $CUSTOM_LOG.Information("Attempting to update module '$module'")
            try {
                Update-Module -Name $module -Confirm:$false -Force:$true
            }
            catch {
                $CUSTOM_LOG.Error("Unable to update module '$module'")
                $CUSTOM_LOG.Error($Error[0])
            }
        }
        else {
            $CUSTOM_LOG.Information("Module '$module' is not installed")
            $CUSTOM_LOG.Information("Attempting to install module '$module'")
            try {
                Install-Module -Name $module -Scope CurrentUser -Confirm:$false -Force:$true -AllowClobber
            }
            catch {
                $CUSTOM_LOG.Error("Unable to install required module '$module'")
                $CUSTOM_LOG.Error($Error[0])
                Exit 1
            }
            if ((Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)) {
                $CUSTOM_LOG.Success("Module '$module' is installed")
            }
            else {
                $CUSTOM_LOG.Fail("Unable to install required module '$module'")
                $CUSTOM_LOG.Error("An unknown error occured")
                $CUSTOM_LOG.Information("Please install the '$module' module using the command below.")
                $CUSTOM_LOG.Information("Install-Module -Name $module -Scope CurrentUser -Confirm:`$false -Force:`$true -AllowClobber")
                Exit 1
            }
        }
    }
}
```
