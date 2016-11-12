function Get-NodeInstallLocation 
{
    <#
    .Synopsis
        Gets the currnet node.js install path
    .Description
        Will return the path that node.js versions will be installed into
    .Example
        Get-NodeInstallLocation
        c:\tmp\.nvm
    #>
  [cmdletbinding()]
  Param(
         [Parameter(Mandatory=$false)][Switch]$Resolve = $false
       )

    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot "settings.json";

    if ((Test-Path $settingsFile) -eq $true) 
    {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    } 
    else 
    {
        $settings = New-Object -TypeName PSObject -Prop @{ InstallPath = (Join-Path $PSScriptRoot 'vs') } #We create a CustomObject that implements the same property 'InstallPath" like the then-path-Json!
    }
    if ($Resolve.IsPresent)
    {
      return Resolve-Path -Path $settings.InstallPath; #ensures a FULL path that MUST exist!
    }
    else
    {
      return $settings.InstallPath;
    }
}
