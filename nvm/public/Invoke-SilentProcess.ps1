Function Invoke-SilentProcess
#Output ?
#usecases 
# not interested on output in case of success
# need output in every case
# erroroutput contains warnings, default-output is empty or has normal content
{ 
    #[Outputtype([string])] ##revision number/last line from log in case of success or EXCEPTION
    [cmdletbinding()]
    param(
             [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$FilePath
            ,[Parameter(Mandatory=$false)][string[]]$Arguments = @()
            ,[Parameter(Mandatory=$false)][ValidateNotNull()][int[]]$ValidExitCodes = @(0)
            ,[Parameter(Mandatory=$false)][Switch]$Quiet = $true #true..no output, false: write-out for output, write warning for errorchannel without exitcode

          )

    $outputFile=[System.IO.Path]::GetTempFileName();
    $outputErrorFile=[System.IO.Path]::GetTempFileName();

    try #try/finally needed for outputfile-cleaning
    {
        $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -NoNewWindow -PassThru -Verbose:$false -RedirectStandardOutput $outputFile -RedirectStandardError $outputErrorFile;
        $handle=$process.Handle; #workaround for missing exitcode on waitforexit;
        if ($handle -eq $null)
        {
            throw "Process not started";
        }
  
        Write-Verbose "Start waiting for process $($process.Id)...";
        $process.WaitForExit();
        Write-Verbose "End waiting for process $($process.Id)...";
        [int]$exitCode = $process.ExitCode;
        Write-Verbose "Process exited ID=$($process.Id), HasExited=$($process.HasExited), ExitCode=$($exitCode)";

        if ($Quiet.IsPresent -eq $false)
        { 
            [String[]]$output=[System.IO.File]::ReadAllLines($outputFile);
            Write-Output ([String]::Join([System.Environment]::NewLine, $output));
        }

        if ($exitCode -in $validExitCodes)
        {
            Write-Verbose "$($FilePath) successfully completed with exitcode $($exitCode), Quiet=$($Quiet.IsPresent)";
            
            if ($Quiet.IsPresent -eq $false)
            { 
              [String[]]$outputError=[System.IO.File]::ReadAllLines($outputErrorFile);
              Write-Warning ([String]::Join([System.Environment]::NewLine, $outputError));
            }
            return;
        }
        else
        {   
            #ExitCode not in ValidExitCode

            [String[]]$outputError=[System.IO.File]::ReadAllLines($outputErrorFile);
            [string]$result = [String]::Empty
            if ($outputError -ne $null)
            {
                $result = [System.String]::Join([System.Environment]::NewLine, $outputError);
            }
            $result=$result.Trim();
            [String]$msg = [System.String]::Format("$($FilePath) returned with ExitCode {1}{0}{2}",[System.Environment]::NewLine, $exitCode, $result);
            throw $msg;
        } #exitcode != 0
    }
    finally
    {
      Remove-Item -Path $outputErrorFile -Force -ErrorAction Ignore| Write-Verbose
      Remove-Item -Path $outputFile -Force -ErrorAction Ignore| Write-Verbose
    }
} #function