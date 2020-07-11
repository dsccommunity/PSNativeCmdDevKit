# Add-SudoPreferenceRule -Executable dpkg -ParameterFilterRule {$_.parameters -contains '-i' -or $_.parameters -contains '--install')}
# Add-SudoPreferenceRule -Executable dpkg -ParameterFilterRule {$_.parameters -contains '-W' -or $_.parameters -contains '--show')} -SudoUser otheruser
# Add-SudoPreferenceRule -EnableSudoForAllCommands
# Add-SudoPreferenceRule -EnableSudoForAllCommands -SudoUser otheruser
# Add-SudoPreferenceRule -DisableSudoForAllCommands

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
        # `-ParameterFilterRule {$args -contains '-i' -or $args -contains '--install'}
        [string]
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
        $Script:SudoAll = switch -regex ($ParameterFilterRule.Trim())
        {
            '^\$true$'  { $true }
            '^\$false$' { $false }
            Default     { $true }
        }

        $script:SudoAllAs = $SudoUser
    }

    $index = $null

    if (Get-SudoPreferenceRule -Executable $Executable -ParameterFilterRule $ParameterFilterRule)
    {
        Write-Warning "Sudo Preference Rule found. Replacing"
        $index = [int](Remove-SudoPreferenceRule -Executable $Executable -ParameterFilterRule $ParameterFilterRule)
    }

    # copy hash with Executable, ParameterFilterRule, and SudoUser if present
    $newRule = @{
        Executable          = $Executable
        ParameterFilterRule = $ParameterFilterRule
        SudoUser            = $SudoUser
    }

    if ($index)
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
