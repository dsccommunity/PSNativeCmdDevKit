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
            $SudoAs = $DefaultSudo.SudoAs
        }
    }

    [string] $Command = $Executable
    [string[]] $CommandParameters = @()

    if ($SudoAs -and ($IsLinux -or $IsMacOS))
    {
        $Command = 'sudo'
        $CommandParameters += '-u'
        $CommandParameters += $SudoAs
        $CommandParameters += $Executable
    }
    elseif ($Sudo -and ($IsLinux -or $IsMacOS))
    {
        $Command = 'sudo'
        $CommandParameters += $Executable
    }

    $CommandParameters += $Parameters

    Write-Verbose -Message "Running #> $Command $CommandParameters"

    # Stream output through the pipeline and mix STDERR with STDOUT.
    & $Command @CommandParameters 2>&1
}
