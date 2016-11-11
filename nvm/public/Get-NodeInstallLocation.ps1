function Get-NodeInstallLocation {
    <#
    .Synopsis
        Gets the currnet node.js install path
    .Description
        Will return the path that node.js versions will be installed into
    .Example
        Get-NodeInstallLocation
        c:\tmp\.nvm
    #>
    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot 'settings.json'

    if ((Test-Path $settingsFile) -eq $true) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    } else {
        $settings = New-Object -TypeName PSObject -Prop @{ InstallPath = (Join-Path $PSScriptRoot 'vs') }
    }

    $settings.InstallPath
}
