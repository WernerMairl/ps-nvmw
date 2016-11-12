#special Compare for System.Versions where Version.Revision is empty/dot defined and two different default values (0, -1) are used!
function Compare-Version
{
    [cmdletbinding()]
    param
    (
         [Parameter(Mandatory=$true)][System.Version]$A #null not allowed => lower complexity
        ,[Parameter(Mandatory=$true)][System.Version]$B #null not allowed => lower complexity
    )

    [int]$result = $A.Major.CompareTo($B.Major);
    if ($result -ne 0)
    {
      return $result;
    }
    
    $result = $A.Minor.CompareTo($B.Minor);
    if ($result -ne 0)
    {
      return $result;
    }

    $result = $A.Build.CompareTo($B.Build);
    if ($result -ne 0)
    {
      return $result;
    }

    #special behavior needed for Revision!

    $result = $A.Revision.CompareTo($B.Revision);
    if ($result -eq 0)
    {
      return $result; #they are equal, everything OK
    }
    
    if (   (($A.Revision -eq 0) -or ($A.Revision -eq -1)) -and (($B.Revision -eq 0) -or ($B.Revision -eq -1)) )
    {
      $result =0; #revision 0 and -1 means likely the same (not defined with two different defaults used in town)
    }
    return $result;

}