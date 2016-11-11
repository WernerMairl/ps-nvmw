function Install-NodeVersion {
    <#
    .Synopsis
        Install a version of node.js
    .Description
        Download and install the specified version of node.js into the nvm directory. Once installed it can be used with Set-NodeVersion
    .Parameter $Version
        The version of node.js to install
    .Parameter $Force
        Reinstall an already installed version of node.js
    .Parameter $architecture
        The architecture of node.js to install, defaults to $env:PROCESSOR_ARCHITECTURE
    .Parameter $proxy
        Define HTTP proxy used when downloading an installer
    .Example
        Install-NodeVersion v5.0.0
        Install version 5.0.0 of node.js into the module directory
    .Example
        Install-NodeVersion v5.0.0 -architecture x86
        Installs the x86 version even if you're on an x64 machine
    .Example
        Install-NodeVersion v5.0.0 -architecture x86 -proxy http://localhost:3128
        Installs the x86 version even if you're on an x64 machine using default CNTLM proxy
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$|^latest$')]
        $Version,

        [switch]
        $Force,

        [string]
        $architecture = $env:PROCESSOR_ARCHITECTURE,
        
        [string]
        $proxy
    )

    if ($version -match "latest") {
        $listing = "https://nodejs.org/dist/latest/"
         $r = (wget -UseBasicParsing $listing).content
         if ($r -match "node-(v[0-9\.]+).*?\.msi") {
             $version = $matches[1]
         }
         else {
             throw "failed to retrieve latest version from '$listing'"
         }
    }

    $nvmwPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmwPath $version

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "node-$version-x86.msi"
    $nodeUrl = "https://nodejs.org/dist/$version/$msiFile"

    if ($architecture -eq 'AMD64') {
        $msiFile = "node-$version-x64.msi"

        if ($version -match '^v0\.\d{1,2}\.\d{1,2}$') {
            $nodeUrl = "https://nodejs.org/dist/$version/x64/$msiFile"
        } else {
            $nodeUrl = "https://nodejs.org/dist/$version/$msiFile"
        }
    }

    if ($proxy) {
        Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile) -Proxy $proxy
    } else {
        Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile)
    }
    

    if (-Not (Get-Command msiexec)) {
        "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.u'
    if (Test-Path $unpackPath) {
        Remove-Item $unpackPath -Recurse -Force
    }

    New-Item $unpackPath -ItemType Directory

    $args = @("/a", (Join-Path $requestedVersion $msiFile), "/qb", "TARGETDIR=`"$unpackPath`"")

    Start-Process -FilePath "msiexec.exe" -Wait -PassThru -ArgumentList $args

    Move-Item (Join-Path (Join-Path $unpackPath 'nodejs') '*') -Destination $requestedVersion -Force
    Remove-Item $unpackPath -Recurse -Force
}
