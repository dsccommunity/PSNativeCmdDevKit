<#
    .SYNOPSIS
        Adds or changes a sudo preference rule.

    .DESCRIPTION
        Registers a command-specific sudo rule or enables or disables sudo for
        every native command. Parameter filters must be script blocks or the
        wildcard string '*'. Script blocks are retained without recompilation.

    .PARAMETER Executable
        Specifies the executable to which the rule applies. Use '*' with a
        wildcard or constant script-block filter to configure all commands.

    .PARAMETER ParameterFilterRule
        Specifies '*' to match every argument list or a script block that
        evaluates the command arguments through its automatic $args variable.

    .PARAMETER EnableSudoForAllCommands
        Enables sudo for every native command.

    .PARAMETER DisableSudoForAllCommands
        Disables the global sudo preference without deleting command rules.

    .PARAMETER SudoUser
        Specifies the user supplied to `sudo -u` when the matching rule applies.

    .EXAMPLE
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule {
            $args -contains '--install'
        }

        Adds a rule that uses sudo for dpkg installation commands.

    .EXAMPLE
        Add-SudoPreferenceRule -EnableSudoForAllCommands -SudoUser 'root'

        Enables sudo for all native commands and selects the root user.
#>

function  Add-SudoPreferenceRule
{
    param
    (

        [Parameter(ParameterSetName = 'Sudo', Mandatory = $true)]
        [Alias('Command')]
        # The binary or command the rule will affect.
        [string]
        $Executable,

        [Parameter(ParameterSetName = 'Sudo', Mandatory = $true)]
        # The Parameter filter to be evaluated for the command.
        # if you want to use sudo for an Executable, regardless of the parameters, use:
        # `-ParameterFilterRule *` or `-ParameterFilterRule {$true}`
        # Otherwise, you can evaluate the Parameters to be used, populated the $Args variable:
        # `-ParameterFilterRule {$args -contains '-i' -or $args -contains '--install'}`
        [object]
        $ParameterFilterRule,

        [Parameter(ParameterSetName = 'SudoAll', Mandatory = $true)]
        # This will Enable sudo for any command, but won't destroy your
        # registered settings. You can set a $SudoUser to be used along.
        [switch]
        $EnableSudoForAllCommands,

        [Parameter(ParameterSetName = 'NoSudoAll', Mandatory = $true)]
        # This will ensure sudo is not automatically added to each command,
        # instead it will use the Sudo Preference rules registered with `Add-SudoPreferenceRule`.
        [switch]
        $DisableSudoForAllCommands,

        [Parameter(ParameterSetName = 'Sudo')]
        [Parameter(ParameterSetName = 'SudoAll')]
        # The executable that is invoked with sudo should be run as this user.
        # the resulting command invoked will be `sudo <sudo user> <executable> <parameters>`.
        [string]
        $SudoUser
    )

    if ($script:SudoPreferenceRules -isnot [System.Collections.ArrayList])
    {
        # There is no default rules store, let's create an array list
        $script:SudoPreferenceRules = [System.Collections.ArrayList]::new()
    }

    if ($PSCmdlet.ParameterSetName -eq 'Sudo' -and
        $ParameterFilterRule -isnot [scriptblock] -and
        $ParameterFilterRule -ne '*')
    {
        throw [System.ArgumentException]::new(
            'ParameterFilterRule must be a ScriptBlock or the wildcard string ''*''.'
        )
    }

    if ($EnableSudoForAllCommands.IsPresent -or $DisableSudoForAllCommands.IsPresent)
    {
        $Script:SudoAll = switch ($PSCmdlet.ParameterSetName)
        {
            NoSudoAll   { $false  }
            SudoAll     { $true   }
        }

        # If sudoUser is specified, set to SudoAllAs. Clean up if disabling SudoAll
        $script:SudoAllAs = $SudoUser
        return
    }
    elseif ($Executable -eq '*')
    {
        $Script:SudoAll = switch ($ParameterFilterRule)
        {
            '*'     { $true }
            default { [bool]$ParameterFilterRule.Invoke() }
        }

        $script:SudoAllAs = $SudoUser
    }

    $index = $null

    if (Get-SudoPreferenceRule -Executable $Executable -ParameterFilterRule $ParameterFilterRule)
    {
        Write-Verbose "Sudo Preference Rule found. Replacing"
        $index = [int](Remove-SudoPreferenceRule -Executable $Executable -ParameterFilterRule $ParameterFilterRule)
    }

    # copy hash with Executable, ParameterFilterRule, and SudoUser if present
    $newRule = @{
        Executable          = $Executable
        ParameterFilterRule = $ParameterFilterRule
        Sudo                = $true
        SudoAs              = $SudoUser
    }

    if ($null -ne $index)
    {
        Write-Debug "Replacing Sudo rule for '$Executable' with filter '$ParameterFilterRule' at index $index"
        $null = $script:SudoPreferenceRules.Insert($index, $newRule)
    }
    else
    {
        Write-Debug "Adding Sudo rule for '$Executable' with filter '$ParameterFilterRule'"
        $null = $script:SudoPreferenceRules.Add($newRule)
    }
}
