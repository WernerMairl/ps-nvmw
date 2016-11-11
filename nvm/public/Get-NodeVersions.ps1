function Get-NodeVersions {
    <#
    .Synopsis
        List local or remote node.js versions
    .Description
        Used to show all the node.js versions installed to nvm, using the -Remote option allows you to list versions of node.js available for install. Providing a -Filter parameter can reduce the versions using the pattern, either local or remote versions
    .Parameter $Remote
        Indicate whether or not to list local or remote versions
    .Parameter $Filter
        A version filter supporting fuzzy filters
    .Example
        Get-NodeVersions -Remote -Filter v4.2
        version
        -------
        v4.2.6
        v4.2.5
        v4.2.4
        v4.2.3
        v4.2.2
        v4.2.1
        v4.2.0
    #>
    param(
        [switch]
        $Remote,

        [string]
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^v\d(\.\d{1,2}){0,2}$')]
        $Filter
    )

    if ($Remote) {
        $versions = Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json

        if ($Filter) {
            $versions = $versions | Where-Object { $_.version.Contains($filter) }
        }

        $versions | Select-Object version | Sort-Object -Descending -Property version
    } else {
        $nvmwPath = Get-NodeInstallLocation

        if (!(Test-Path -Path $nvmwPath)) {
            "No Node.js versions have been installed"
        } else {
            $versions = Get-ChildItem $nvmwPath | %{ $_.Name }

            if ($Filter) {
                $versions = $versions | Where-Object { $_.Contains($filter) }
            }

            $versions | Sort-Object -Descending
        }
    }
}