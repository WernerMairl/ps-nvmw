function Set-NodeVersion {
    <#
    .Synopsis
       Set the node.js version for the current session
    .Description
       Set's the node.js version that was either provided with the -Version parameter or from using the .nvmrc file in the current working directory.
    .Parameter $Version
       A version string for the node.js version you wish to use. Use the format of v#.#.#. This also supports fuzzy matching, so v# will be the latest installed version starting with that major
    .Parameter $Persist
       If present, this will also set the node.js version to the permanent system path, of the specified scope, which will persist this setting for future powershell sessions and causes this version of node.js to be referenced outside of powershell.
    .Example
       Set based on the .nvmrc
       Set-NodeVersion
    .Example
       Set-NodeVersion v5
       Set using fuzzy matching
    .Example
       Set-NodeVersion v5.0.1
       Set using explicit version
    .Example
       Set-NodeVersion v5.0.1 -Persist User
       Set and persist in permamant system path for the current user
    .Example
       Set-NodeVersion v5.0.1 -Persist Machine
       Set and persist in permamant system path for the machine (Note: requires an admin shell)
    #>
    param(
        [string]
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^v\d(\.\d{1,2}){0,2}$')]
        $Version,
        [string]
        [ValidateSet('User', 'Machine')]
        [Parameter(Mandatory=$false)]
        $Persist
    )

    if ([string]::IsNullOrEmpty($Version)) {
        if (Test-Path .\.nvmrc) {
            $VersionToUse = Get-Content .\.nvmrc -Raw
        }
        else {
            "Version not given and no .nvmrc file found in folder"
            return
        }
    }
    else {
        $VersionToUse = $version
    }

    $VersionToUse = $VersionToUse.replace("`n","").replace("`r","")

    if (!($VersionToUse -match "v\d\.\d{1,2}\.\d{1,2}")) {
        "Version found is not a full version, using fuzzy matching"
        $VersionToUse = Get-NodeVersions -Filter $VersionToUse | Select-Object -First 1

        if (!$VersionToUse) {
            "No version found to fuzzy match against"
            return
        }
    }

    $nvmwPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmwPath $VersionToUse

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $VersionToUse"
        return
    }

    # immediately add to the current powershell session path
    $env:Path = "$requestedVersion;$env:Path"

    if ($Persist -ne '') {
        # also add to the permanent windows path
        $persistedPaths = @($requestedVersion)
        [Environment]::GetEnvironmentVariable('Path', $Persist) -split ';' | % {
          if (-not($_ -like "$nvmwPath*")) {
            $persistedPaths += $_
          }
        }
        [Environment]::SetEnvironmentVariable('Path', $persistedPaths -join ';', $Persist)
    }

    $env:NODE_PATH = "$requestedVersion;"
    npm config set prefix $requestedVersion
    $env:NODE_PATH += npm root -g

    "Switched to node version $VersionToUse"
}
