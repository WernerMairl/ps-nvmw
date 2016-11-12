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

    [cmdletbinding(DefaultParameterSetName="Latest")]
    param(
         [Parameter(Mandatory=$false, ParameterSetName="Latest")][Switch]$Latest=$true
        ,[Parameter(Mandatory=$false, ParameterSetName="Version")][ValidateScript({Validate-Version -Version $_})][string]$Version
        ,[Parameter(Mandatory=$false, ParameterSetName="Fuzzy")][Switch]$Fuzzy=$false
        ,[ValidateSet("Process", "User", "Machine")][Parameter(Mandatory=$false)][string]$Persist = "Process" #current process is the default!
        ,[Parameter(Mandatory=$false)][Switch]$Force=$false #ensure re-activate with the provided value for $Persist argument 
    )

    #Changes by WM 11/2016
    #added ParameterSets and cmdletbinding
    #added "Never" to Parameter "Persist" => Q: the SetEnvironmentVariable command uses User/Machine/Process, should/can we do the same ?
    #strings should NEVER be written direct to the pipeline => they goes to the host! Use Write-Verbose (et.al) for that
    #deactivate/detect current version seems NOT to be coded...first try!
    #access and calculation of environmentvariable PATH rewritten/refactored!


    [System.Version]$VersionToUse = $null;
    if ($PSCmdlet.ParameterSetName -eq "Version")
    {
        $VersionToUse = Validate-Version -Version $Version -Passthrough;
    }


    #fuzzy matching causes a lot of risk and complexity, specially on the api-surface. We should remove that or at least remove the feature from the Parameter "Version" and use another Parameter (Set) for this!
    <#
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
    #>
    <#
    if (!($VersionToUse -match "v\d\.\d{1,2}\.\d{1,2}")) {
        "Version found is not a full version, using fuzzy matching"
        $VersionToUse = Get-NodeVersions -Filter $VersionToUse | Select-Object -First 1

        if (!$VersionToUse) {
            "No version found to fuzzy match against"
            return
        }
    }
    #>
    if ($VersionToUse -eq $null)
    {
      throw "VersionToUse not calculated! Something with the parameters goes wrong or not implemented ParameterSet $($PSCmdlet.ParameterSetName)."
    }

    $npmCommand=Get-Command -Name "npm" -ErrorAction Ignore; #it returns not null if some npm is installed/available!
    $nodeCommand=Get-Command -Name "node.exe" -ErrorAction Ignore;

    if ($Force.IsPresent -eq $false)
    {
        if (($npmCommand -ne $Null) -and ($nodeCommand -ne $null))
        {
          #some version is active, we must find out if it is the requested!
          [int]$compare = Compare-Version $nodeCommand.Version $VersionToUse;
          if ($compare -eq 0)
          {
            #PROBLEM/RISK: a version is installed BUT Parameter "Persist" can have different value. not sure if we can check that here!
            Write-Verbose "The requested version $($VersionToUse.ToString()) is currently active in folder $($nodeCommand.Source)";
            return;
          }
        }
    }
    else
    {
      Write-Verbose "-Force is selected";
    }

    $nvmwPath = Get-NodeInstallLocation -Resolve:$true; #Resolve ensures a FULL Path name (we need that for env:Path) and it throws a exception if the path not exists => 0 installed versions => exception OK!
    [string]$foldername = $VersionToUse.ToString();
    $installFolderPath = Join-Path $nvmwPath $foldername;
    [bool]$folderExists=Test-Path -Path $installFolderPath;

    if ($folderExists -eq $false)
    {
        # error management/exception !?
        Write-Verbose "Could not find node version $($VersionToUse.ToString())";
        return
    }

    #depending on the Persist-Level we must write the PATH variable multiple times!
    #1. for the current process: ALWAYS 
    Update-EnvironmentPathVariable -Name "Path" -Value $installFolderPath -ReplaceMask "$($nvmwPath)*" -Persist "Process";

    #2. one time for the Persist Mode if it is NOT Process => means to use fo the next started process for that machine/user
    if ($Persist -ne "Process")
    {
      Update-EnvironmentPathVariable -Name "Path" -Value $installFolderPath -ReplaceMask "$($nvmwPath)*" -Persist $Persist;
    }

    Update-EnvironmentPathVariable -Name "Path" -Value $installFolderPath -ReplaceMask "$($nvmwPath)*" -Persist $Persist;

    $env:NODE_PATH = "$($installFolderPath);"
    npm config set prefix $installFolderPath
    $env:NODE_PATH += npm root -g

    Write-Verbose "Switched to node version $($VersionToUse.ToString())"
}
