function Validate-Version
{
    [cmdletbinding()]
    param
    (
        [string]$Version
        ,[Switch]$Passthrough = $false
    )
    [System.Version]$result=$null;
    [bool]$success=$false;

    if ([string]::IsNullOrEmpty($Version) -eq $false)
    {
      if ($Version.StartsWith("v",$false, [System.Globalization.CultureInfo]::InvariantCulture))
      {
         $Version = $Version.Substring(1);
      }
      $success = [System.Version]::TryParse($Version,[ref]$result);
    }

    ## Result Handling

    if ($Passthrough.IsPresent)
    {
      return $result;
    }
    else
    {
      return $success;
    }
}