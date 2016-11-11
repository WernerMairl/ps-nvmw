function Set-NodeInstallLocation {
    <#
    .Synopsis
        Sets the path where node.js versions will be installed into
    .Description
        This is used to override the default node.js install path for nvm, which is relative to the module install location. You would want to use this to get around the Windows path limit problem that plagues node.js installed. Note that to avoid collisions the unpacked files will be in a folder `.nvm\<version>` in the specified location.
    .Parameter $Path
        THe root folder for nvm
    .Example
        Set-NodeInstallLocation -Path C:\Temp
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        $Path
    )

    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot 'settings.json'

    if ((Test-Path $settingsFile) -eq $true) {
        $settings = Get-Content $settings | ConvertFrom-Json
    } else {
        $settings = @{ 'InstallPath' = Get-NodeInstallLocation }
    }

    $settings.InstallPath = Join-Path $Path '.nvm'

    ConvertTo-Json $settings | Out-File (Join-Path $PSScriptRoot 'settings.json')
}
