#WM 30.09.2016 refactored from ContinuosIntegration.psm1

function Invoke-ZipExtract
{
<#
.SYNOPSIS
    extracts the zip file to target folder
    
.PARAMETER zipfile
File path of the zip file

.PARAMETER targetFolder
Folder path of the destination for artefact

#>
[cmdletbinding()]
param(
     [Parameter(Mandatory=$true)][string]$ZipFilePath
    ,[Parameter(Mandatory=$true)][string]$TargetFolderPath
    ,[Parameter(Mandatory=$false)][Switch]$Force=$false
)

    Write-Verbose "Expected Zip File: $ZipFilePath"
    Write-Verbose "Target Folder: $TargetFolderPath"

    $tempTargetFolder = $TargetFolderPath
    if ($Force.IsPresent)
    {
      $randomDirName = [System.IO.Path]::GetRandomFileName();
      $tempTargetFolder= Join-Path $env:TEMP  $randomDirName
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory( $ZipFilePath, $tempTargetFolder )

    if ($Force.IsPresent)
    {

        if(Test-Path $TargetFolderPath -PathType Container)
        {
            Remove-Item $TargetFolderPath -Force -Recurse | Out-Null
        }

        New-Item -ItemType Directory -Path $TargetFolderPath |Out-Null

        $source = Join-Path $tempTargetFolder "*";
        try
        {
            Copy-ITem -Path $source -Destination $TargetFolderPath -Recurse -Force | Out-Null
        }
        catch
        {
            throw "Error: Copying files from TEMP folder in Invoke-ZipExtract"
        }
        finally
        {
            Remove-Item -Path $tempTargetFolder  -Recurse -Force -ErrorAction Continue | Out-Null;
        }
      #delete $tempTargetfolder
    }

    #Write-Verbose "Extracted files & folders"
    #dir $targetFolder | Write-Verbose
} #Invoke-ZipExtract
