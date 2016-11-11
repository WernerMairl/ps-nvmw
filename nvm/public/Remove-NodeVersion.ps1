
function Remove-NodeVersion {
    <#
    .Synopsis
        Removes an installed version of node.js
    .Description
        Removes an installed version of node.js along with any installed npm modules
    .Parameter $Version
        The full version string of the node.js package to remove
    .Example
        Remove-NodeVersion v5.0.0
        Removes the v5.0.0 version of node.js from the nvm store
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $nvmwPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmwPath $Version

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $Version"
        return
    }

    Remove-Item $requestedVersion -Force -Recurse
}
