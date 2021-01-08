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
        [AllowNull()]
        # Specify a user to sudo he command as. i.e.: `sudo -u otheruser ls -alh`.
        # If nothing is specified the User option is not used (`sudo command`)
        [String]
        $SudoAs,

        [pscredential]
        # User Credential so that its Password can be passed to sudo via echo `$Password | sudo -S your_sudo_command`.
        # this should be your current password, and your account should be allowed to execute the command in
        # the sudoers files.
        $Credential, #= $((Get-Credential -UserName $env:user -Message "Enter your credential for sudo authorisation")),

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

    [string[]]$CommandExpression = @()

    if ($SudoAs -and ($IsLinux -or $IsMacOS))
    {
        if ($Credential) {
            $commandExpression +=  ('echo "{0}" | sudo -u {1} -S {2}' -f $Credential.GetNetworkCredential().Password, $SudoAs, $Executable)
        }
        else {
            $commandExpression += "sudo -u $SudoAs $Executable"
        }
    }
    elseif ($Sudo -and ($IsLinux -or $IsMacOS))
    {
        if ($Credential) {
            $commandExpression +=  ('echo "{0}" | sudo -S {1}' -f $Credential.GetNetworkCredential().Password, $Executable)
        }
        else {
            $commandExpression += "sudo $Executable"
        }
    }
    elseif ($IsWindows -and $Credential) {
        throw "runAs not implemented yet"
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
