Describe 'Sudo preference rules' {
    BeforeAll {
        $script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . "$script:ProjectRoot\source\Public\Get-SudoPreferenceRule.ps1"
        . "$script:ProjectRoot\source\Public\Remove-SudoPreferenceRule.ps1"
        . "$script:ProjectRoot\source\Public\Add-SudoPreferenceRule.ps1"
        . "$script:ProjectRoot\source\Public\Get-SudoPreference.ps1"
    }

    BeforeEach {
        $script:SudoPreferenceRules = [System.Collections.ArrayList]::new()
        $script:SudoAll = $false
        $script:SudoAllAs = $null
    }

    It 'retains and invokes a supplied script block directly' {
        $filter = { $args -contains '--install' }
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $filter

        $storedRule = Get-SudoPreferenceRule -Executable 'dpkg'
        $storedRule.ParameterFilterRule | Should -Be $filter
        Get-SudoPreference -Executable 'dpkg' -Parameters '--install' |
            Should -Not -BeNullOrEmpty
        Get-SudoPreference -Executable 'dpkg' -Parameters '--list' |
            Should -BeNullOrEmpty
    }

    It 'supports the wildcard without compiling source code' {
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'

        Get-SudoPreference -Executable 'dpkg' -Parameters '--anything' |
            Should -Not -BeNullOrEmpty
    }

    It 'rejects string expressions' {
        {
            Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '$true'
        } | Should -Throw
    }

    It 'preserves the language mode of a constrained caller script block' {
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()

        try {
            $bootstrap = [powershell]::Create()
            $bootstrap.Runspace = $runspace
            $null = $bootstrap.AddScript(@"
. '$script:ProjectRoot\source\Public\Get-SudoPreferenceRule.ps1'
. '$script:ProjectRoot\source\Public\Remove-SudoPreferenceRule.ps1'
. '$script:ProjectRoot\source\Public\Add-SudoPreferenceRule.ps1'
. '$script:ProjectRoot\source\Public\Get-SudoPreference.ps1'
"@)
            $null = $bootstrap.Invoke()
            $bootstrap.HadErrors | Should -BeFalse
            $bootstrap.Dispose()

            $runspace.SessionStateProxy.LanguageMode =
                [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage

            $caller = [powershell]::Create()
            $caller.Runspace = $runspace
            $null = $caller.AddScript(@'
$filter = {
    $global:ObservedLanguageMode = $ExecutionContext.SessionState.LanguageMode
    $true
}
Add-SudoPreferenceRule -Executable 'test' -ParameterFilterRule $filter
$null = Get-SudoPreference -Executable 'test'
$global:ObservedLanguageMode
'@)

            $result = $caller.Invoke()
            $caller.HadErrors | Should -BeFalse
            $result[-1] | Should -Be 'ConstrainedLanguage'
            $caller.Dispose()
        }
        finally {
            $runspace.Dispose()
        }
    }
}
