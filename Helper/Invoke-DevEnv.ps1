[cmdletbinding()]
param()

    $ErrorActionPreference="Stop";
    $thisPath = Split-Path -Parent $MyInvocation.MyCommand.Path;

    if ($Host.Name -like "*ISE*") #unload module to ensure reload with the LATEST changes!
    {
       cls;
       Remove-Module -Name "nvm" -Force -ErrorAction Ignore -Verbose:$false |Out-Null;
    }

    if(-not (Get-Module -name 'nvm')) 
    {
        $moduleFile = Join-Path $thisPath '..\nvm\nvm.psd1' -Resolve;
        Import-Module $moduleFile -Verbose:$false |Out-Null
    }

## Now the current module is loaded and can be called for dev/debug
Get-NodeVersions -Remote

#Install-NodeVersion -Version "v0.1.100";
