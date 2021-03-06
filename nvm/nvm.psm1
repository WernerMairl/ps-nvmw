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

#In Windows PowerShell 3.0, if you send it a collection of object and ask for a property that the collection doesn’t have, Windows PowerShell checks to see if the objects in the collection have that property and, if they do, it returns the property value. (Try: (Get-Process).Name ).


[bool]$exportVerbosity=$false; #only for debug!
Export-ModuleMember -Function $Public.Basename -Verbose:$exportVerbosity | Write-Verbose; #Export Public functions


