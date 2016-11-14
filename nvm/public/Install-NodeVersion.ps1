function Install-NodeVersion 
{
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
        Install-NodeVersion
        Install latest version of node.js into the module directory. "latest" is defined by https://nodejs.org/dist/latest/
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
    [cmdletbinding(DefaultParameterSetName="Latest")]
    param(
         [Parameter(Mandatory=$false, ParameterSetName="Latest")][Switch]$Latest=$true
        ,[Parameter(Mandatory=$false, ParameterSetName="Version")][ValidateScript({Validate-Version -Version $_})][string]$Version
        ,[Parameter(Mandatory=$false)][switch]$Force = $false
        ,[Parameter(Mandatory=$false)][ValidateSet("x86","x64", "AMD64", "IA64")][string]$Architecture = $env:PROCESSOR_ARCHITECTURE  #https://msdn.microsoft.com/en-us/library/aa384274.aspx
        ,[Parameter(Mandatory=$false)][string]$Proxy
    )
    
    # Install Strategy
    # nodejs.org provides msi packages BUT we use/handle them like zip files.
    # Means: we extract them in administrative mode so we can have multiple installations in parallel => MSI/Windows requires always only ONE Version installed!

    #Lessons learned
    #  there are a lot of versions available for download on 'https://nodejs.org/dist' but not every version has windows installer and our code throws exceptions (without meaningful wording/explanation why). 
    #  We should improve the exception messages for usability in this case.
 

    #1. caluclate the System.Version that should be installed

    [System.Version]$resolvedVersion=$null;

    if ($PSCmdlet.ParameterSetName -eq "Latest")
    {
        if ($Latest.IsPresent -eq $false)
        {
            throw "ParameterSet Latest is used bute Switch is set to false => not supported";
        }
        $listing = "https://nodejs.org/dist/latest/"
        $r = (wget -UseBasicParsing $listing).content
        if ($r -match "node-(v[0-9\.]+).*?\.msi") 
        {
            $resolvedVersion = $matches[1]
        }
        else 
        {
            throw "failed to retrieve latest version from '$listing'"
        }
    }
    else #assuming ParameterSet "Version"
    {
       $resolvedVersion=Validate-Version $Version -Passthrough;
    }

    if ($resolvedVersion -eq $null)
    {
      throw "something goes wrong internally";
    }
    #2. ensure that msi is available

    $msiExecCommand=Get-Command -Name "msiexec" -ErrorAction Stop; #throw a execption if not available in the path => NANO Server !?

    #3. calculate and check the install folder/existing installation
    $nvmwPath = Get-NodeInstallLocation
    [string]$foldername = $resolvedVersion.ToString();
    $installFolderPath = Join-Path $nvmwPath $foldername;
    [bool]$folderExists=Test-Path -Path $installFolderPath;

    if ($folderExists) 
    {
        if ($Force.IsPresent -eq $false)
        {
            #TODO we should define a PSObject for outpit with all the details => empty folder causes NO install!
            return;
        }
        else
        {
          ##TODO uninstall current installed version AND delete the folder (remaining items AFTER uninstall)
          ##Uninstall means remove the folder (structure) => msi is used ONLX in administrative mode, not in full mode => deleting is allowed!
          $folderExists=Test-Path -Path $installFolderPath ; #refresh $folderExists!
        }
    }
    
    if ($folderExists -eq $false)
    {
        [System.IO.Directory]::CreateDirectory($installFolderPath) | Out-Null;
    }

    if ($resolvedVersion.Revision -ne -1)
    {
      throw "probably unexpected value for NodeJS.org folder structure";
    }
    [string]$nodeVersionLabel = "v$($resolvedVersion.ToString())"; #$Version.Tostring results WITHOUT Revision Part if it is -1!;
    
    [string]$msiFile = "node-$($nodeVersionLabel)-x86.msi";
    $nodeUrl = "https://nodejs.org/dist/$($nodeVersionLabel)/$($msiFile)";

    if ($architecture -eq 'AMD64') 
    {
        $msiFile = "node-$nodeVersionLabel-x64.msi"

        if ($version -match '^v0\.\d{1,2}\.\d{1,2}$') {
            $nodeUrl = "https://nodejs.org/dist/$nodeVersionLabel/x64/$msiFile"
        } else {
            $nodeUrl = "https://nodejs.org/dist/$nodeVersionLabel/$msiFile"
        }
    }

    $outfile=Join-Path $installFolderPath $msiFile;
    $cache=$false;
    if ($cache -eq $false)
    {
        Write-Verbose "Web-Request Url: $($nodeUrl)";
        if ([string]::IsNullOrEmpty($Proxy) -eq $false) 
        {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $outfile -Proxy $Proxy;
        } 
        else 
        {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $outfile;
        }
    }
    $unpackPath = Join-Path $installFolderPath '.u' #???
    if (Test-Path $unpackPath) 
    {
        Remove-Item $unpackPath -Recurse -Force
    }

    New-Item $unpackPath -ItemType Directory

    $args = @("/a", $outfile, "/qb", "TARGETDIR=`"$unpackPath`"")

    Start-Process -FilePath "msiexec.exe" -Wait -PassThru -ArgumentList $args

    Move-Item (Join-Path (Join-Path $unpackPath 'nodejs') '*') -Destination $installFolderPath -Force
    Remove-Item $unpackPath -Recurse -Force
}
