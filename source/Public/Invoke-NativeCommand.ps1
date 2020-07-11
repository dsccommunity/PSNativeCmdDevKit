function Invoke-NativeCommand
{
    [cmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Command')]
        # The binary or command you would like to execute.
        [string]
        $Executable,

        [Parameter()]
        # Whether you want to sudo the command invocation, on non-windows OSes.
        # If you want to sudo as a different user, use the parameter `-SudoAs`.
        [switch]
        $Sudo,

        [Parameter()]
        # Specify a user to sudo he command as. i.e.: `sudo otheruser ls -alh`
        [String]
        $SudoAs,

        [Parameter()]
        # list of Parameters to pass to the invocation.
        # For binaries and commands requiring a specific order
        # make sure it is respected as no further check is done.
        [String[]]
        $Parameters
    )

    # If Sudo or SudoAs is not specified, lookup in the Module variable DefaultCommandToSudo
    if ( -not ($PSBoundParameters.ContainsKey('Sudo') -or $PSBoundParameters.ContainsKey('SudoAs')) )
    {
        if ($DefaultSudo = Get-SudoPreference @PSBoundParameters)
        {
            $Sudo   = $DefaultSudo.Sudo
            $SudoAs = $DefaultSudo
        }

    }

    [string[]]$CommandExpression = @()

    if ($SudoAs -and ($IsLinux -or $IsMacOS))
    {
        $commandExpression += "sudo -u $SudoAs $Executable"
    }
    elseif ($Sudo -and ($IsLinux -or $IsMacOS))
    {
        $commandExpression += "sudo $Executable"
    }
    else
    {
        $commandExpression += $Executable
    }

    $commandExpression += $Parameters

    # Mixes the Error stream and the success streams (redirect STDERR with STDOUT)
    # What was in STDERR will be of type [ErrorRecord] if you need to differentiate for parsing.
    $commandExpression += '2>&1'

    Write-Verbose -Message "Running #> $commandExpression"
    [scriptblock]$commandExpression = [scriptblock]::create($commandExpression)

    # Stream the output through the pipeline
    & $commandExpression
}
