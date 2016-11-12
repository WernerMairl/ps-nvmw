#Adds a new value to EnvironmentVariables like "PATH" (added string with ";" as separator)
#Process,User and Machine can be selected
#old values con be removed/replaced by using $ReplaceMask
function Update-EnvironmentPathVariable 
{
    [cmdletbinding()]
    param
    (
          [Parameter(Mandatory=$true)][string]$Name
         ,[Parameter(Mandatory=$true)][string]$Value
         ,[ValidateSet("Process", "User", "Machine")][Parameter(Mandatory=$false)][string]$Persist #no defaults used on internal/private!
         ,[Parameter(Mandatory=$false)][string]$ReplaceMask 

    )
    [System.EnvironmentVariableTarget]$target = $Persist; #Powershell integrated Typecasting system should do the work!
    Write-Verbose "EnvironemntTarget=$($target)";
    [string]$currentPath = [Environment]::GetEnvironmentVariable($Name,$target); #empty variable does not cause exception here or later (verified)!!

    [string[]]$parts=@($Value); ##add new value as first!
    foreach ($item in ($currentPath -split ";"))
    {
      if ([string]::IsNullOrEmpty($item))
      {
        continue; #don't add this item. this occurs in case where $currentpath is $null (empty/not existing variable)
      }
      if ([string]::IsNullOrEmpty($ReplaceMask) -eq $false)
      {
          if ($item -like "$($ReplaceMask)*") #basefolder+wildcard means: every active version that is located inside our Get-NodeInstallLocation
          {
            continue; #don't add this Item!
          }
      }
      $parts+=$item;
    }
    [string]$newPath=$parts -join ";";
    [Environment]::SetEnvironmentVariable($Name, $newPath, $target); 
}
