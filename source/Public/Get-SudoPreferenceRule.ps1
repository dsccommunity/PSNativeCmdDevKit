<#
    .SYNOPSIS
        Gets registered sudo preference rules.

    .DESCRIPTION
        Returns all registered rules or filters rules by executable and,
        optionally, by the exact parameter-filter object.

    .PARAMETER Executable
        Specifies the executable whose registered rules should be returned.

    .PARAMETER ParameterFilterRule
        Specifies the exact script block or wildcard filter to match.

    .PARAMETER All
        Returns every registered sudo preference rule.

    .EXAMPLE
        Get-SudoPreferenceRule -Executable 'dpkg'

        Returns all rules registered for dpkg.
#>

function  Get-SudoPreferenceRule
{
    [CmdletBinding(DefaultParameterSetName = 'all')]
    [OutputType([System.Object[]])]
    param
    (

        [Parameter(ParameterSetName = 'byCommand', Mandatory = $true)]
        [Alias('Command')]
        # The binary or command to be executed.
        [string]
        $Executable,

        [Parameter(ParameterSetName = 'byCommand')]
        [object]
        $ParameterFilterRule,

        [Parameter(ParameterSetName = 'all')]
        [switch]
        $All

    )

    if ($script:SudoPreferenceRules -isnot [System.Collections.ArrayList])
    {
        # There is no default rules store, let's create an array list and return it
        $script:SudoPreferenceRules = [System.Collections.ArrayList]::new()
    }

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $script:SudoPreferenceRules
    }
    else
    {
        $script:SudoPreferenceRules.Where{
            $_.Executable -eq $Executable -and
            $(
                if ($ParameterFilterRule -and $ParameterFilterRule -ne '*')
                {
                    $_.ParameterFilterRule -eq $ParameterFilterRule
                }
                else
                {
                    $true
                }
            )
        }
    }
}
