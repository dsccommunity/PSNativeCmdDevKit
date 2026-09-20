<#
    .SYNOPSIS
        Removes registered sudo preference rules.

    .DESCRIPTION
        Removes rules by executable and filter, by internal index, or clears
        every registered rule.

    .PARAMETER Executable
        Specifies the executable whose matching rules should be removed.

    .PARAMETER ParameterFilterRule
        Specifies the exact script block or wildcard filter to remove.

    .PARAMETER Index
        Specifies the internal zero-based rule index to remove.

    .PARAMETER All
        Removes every registered sudo preference rule.

    .EXAMPLE
        Remove-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'

        Removes wildcard sudo rules registered for dpkg.
#>

function Remove-SudoPreferenceRule
{
    [cmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'ByValue', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Command')]
        # The executable that has the rule applied to.
        [string]
        $Executable,

        [Parameter(ParameterSetName = 'ByValue', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        # The parameter filter rule to match with the executable to remve.
        [object]
        $ParameterFilterRule,

        [Parameter(Dontshow = $true, ParameterSetName = 'ByIndex', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        # Remove the Rule stored in the module's $script:SudoPreferenceRules by its index (advanced user only)
        [int]
        $index,

        [Parameter(ParameterSetName = 'All', Mandatory = $true)]
        # Remove all previously registered rules.
        [switch]
        $All
    )

    begin
    {
        if ($script:SudoPreferenceRules -isnot [System.Collections.ArrayList])
        {
            # There is no default rules store
            return
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByIndex')
        {
            $script:SudoPreferenceRules.RemoveAt($Index)
            return
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $script:SudoPreferenceRules.Clear()
            return
        }

        $CurrentIndex = 0
        $indexesToRemove = $script:SudoPreferenceRules.Foreach{
            if ($_.Executable -eq $Executable -and
                ($_.ParameterFilterRule -eq '*' -or $_.ParameterFilterRule -eq $ParameterFilterRule)
            )
            {
                $CurrentIndex
            }

            $CurrentIndex++
        }

        $indexesToRemove |
            Sort-Object -Descending |
            ForEach-Object {
            $script:SudoPreferenceRules.RemoveAt($_)
            # return the Indexes where the rule has been removed
            $_
        }
    }
}
