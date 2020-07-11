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
            $Sudo = $true
            $SudoAs = $script:SudoAllAs
        }
    }
    elseif ($script:SudoPreferenceRules)
    {
        $enumerator = $script:SudoPreferenceRules.GetEnumerator()
        $RuleMatchFound = $false
        while ($enumerator.MoveNext() -and -not $RuleMatchFound)
        {
            $RuleMatchFound = $script:SudoPreferenceRules | Where-Object -FilterScript {
                $Executable -eq $_.Executable -and
                ($_.ParameterFilterRule.ToString().Trim() -eq '*' -or [scriptblock]::create($_.ParameterFilterRule).Invoke($Parameters))
            } | Select-Object -First 1
        }

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
