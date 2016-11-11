#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path "$($PSScriptRoot)\Public\*.ps1" -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path "$($PSScriptRoot)\Private\*.ps1" -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($importedFile in @($Public + $Private))
    {
        Try
        {
            . $importedFile.Fullname 
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($importedFile.fullname): $($_)"
        }
    }

[bool]$exportVerbosity=$true;
Export-ModuleMember -Function $Public.Basename -Verbose:$exportVerbosity | Write-Verbose; #Export Public functions


