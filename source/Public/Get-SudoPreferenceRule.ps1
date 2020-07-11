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
        [string]
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
                if ($ParameterFilterRule -and $ParameterFilterRule.Trim() -ne '*')
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
