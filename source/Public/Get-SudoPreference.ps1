<#
    .SYNOPSIS
        Resolves the sudo preference for a native command.

    .DESCRIPTION
        Returns the first global or command-specific sudo preference whose
        executable and argument filter match the supplied invocation.

    .PARAMETER Executable
        Specifies the executable for which to resolve a sudo preference.

    .PARAMETER Parameters
        Specifies the native argument values evaluated by script-block filters.

    .EXAMPLE
        Get-SudoPreference -Executable 'dpkg' -Parameters '--install', 'package.deb'

        Returns the matching sudo preference, when one is registered.
#>

function Get-SudoPreference
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Command')]
        # The binary or command to be executed.
        [string]
        $Executable,

        [Parameter()]
        # List of parameters to pass to the invocation that will be
        # evaluated against the registered Sudo Preference Rules.
        [String[]]
        $Parameters
    )

    if ($script:SudoAll)
    {
        @{
            Sudo   = $true
            SudoAs = $script:SudoAllAs
        }
    }
    elseif ($script:SudoPreferenceRules)
    {
        $RuleMatchFound = $script:SudoPreferenceRules | Where-Object -FilterScript {
            $Executable -eq $_.Executable -and
            ($_.ParameterFilterRule -eq '*' -or $_.ParameterFilterRule.Invoke($Parameters))
        } | Select-Object -First 1

        if ($RuleMatchFound)
        {
            return [hashtable]$RuleMatchFound
        }
        else
        {
            Write-Debug "No matching rules for '$Executable' with params '$Parameters'"
        }
    }
}
