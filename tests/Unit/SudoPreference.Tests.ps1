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

    It 'Should retain and invoke a supplied script block directly' {
        $filter = { $args -contains '--install' }
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $filter

        $storedRule = Get-SudoPreferenceRule -Executable 'dpkg'
        $storedRule.ParameterFilterRule | Should -Be $filter
        $preference = Get-SudoPreference -Executable 'dpkg' -Parameters '--install'
        $preference.Sudo | Should -BeTrue
        $preference.SudoAs | Should -BeNullOrEmpty
        Get-SudoPreference -Executable 'dpkg' -Parameters '--list' |
            Should -BeNullOrEmpty
    }

    It 'Should support the wildcard and preserve the sudo user' {
        Add-SudoPreferenceRule `
            -Executable 'dpkg' `
            -ParameterFilterRule '*' `
            -SudoUser 'service-user'

        $preference = Get-SudoPreference -Executable 'dpkg' -Parameters '--anything'
        $preference.Sudo | Should -BeTrue
        $preference.SudoAs | Should -Be 'service-user'
    }

    It 'Should reject string expressions' {
        {
            Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '$true'
        } | Should -Throw
    }

    It 'Should replace a matching rule at index zero' {
        $firstFilter = { $args -contains '--install' }
        $replacementFilter = { $args -contains '--remove' }

        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $firstFilter
        Add-SudoPreferenceRule -Executable 'apt' -ParameterFilterRule '*'
        Add-SudoPreferenceRule `
            -Executable 'dpkg' `
            -ParameterFilterRule $firstFilter `
            -SudoUser 'root' `
            -WarningAction SilentlyContinue

        $rules = @(Get-SudoPreferenceRule -All)
        $rules | Should -HaveCount 2
        $rules[0].Executable | Should -Be 'dpkg'
        $rules[0].SudoAs | Should -Be 'root'

        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $replacementFilter
        @(Get-SudoPreferenceRule -All) | Should -HaveCount 3
    }

    It 'Should enable and disable sudo for all commands' {
        Add-SudoPreferenceRule -EnableSudoForAllCommands -SudoUser 'root'

        $preference = Get-SudoPreference -Executable 'anything'
        $preference.Sudo | Should -BeTrue
        $preference.SudoAs | Should -Be 'root'

        Add-SudoPreferenceRule -DisableSudoForAllCommands
        Get-SudoPreference -Executable 'anything' | Should -BeNullOrEmpty
        $script:SudoAllAs | Should -BeNullOrEmpty
    }

    It 'Should evaluate an all-command script block without recompiling it' {
        Add-SudoPreferenceRule -Executable '*' -ParameterFilterRule { $false }
        $script:SudoAll | Should -BeFalse

        Add-SudoPreferenceRule -Executable '*' -ParameterFilterRule { $true }
        $script:SudoAll | Should -BeTrue
    }

    It 'Should return rules by executable and filter' {
        $filter = { $true }
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $filter
        Add-SudoPreferenceRule -Executable 'apt' -ParameterFilterRule '*'

        @(Get-SudoPreferenceRule -Executable 'dpkg') | Should -HaveCount 1
        @(Get-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule $filter) |
            Should -HaveCount 1
        Get-SudoPreferenceRule -Executable 'missing' | Should -BeNullOrEmpty
    }

    It 'Should remove a rule by value' {
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'
        Add-SudoPreferenceRule -Executable 'apt' -ParameterFilterRule '*'

        Remove-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'

        @(Get-SudoPreferenceRule -All) | Should -HaveCount 1
        Get-SudoPreferenceRule -Executable 'dpkg' | Should -BeNullOrEmpty
    }

    It 'Should remove a rule by index' {
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'
        Add-SudoPreferenceRule -Executable 'apt' -ParameterFilterRule '*'

        Remove-SudoPreferenceRule -Index 0

        $rules = @(Get-SudoPreferenceRule -All)
        $rules | Should -HaveCount 1
        $rules[0].Executable | Should -Be 'apt'
    }

    It 'Should remove all rules' {
        Add-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*'
        Add-SudoPreferenceRule -Executable 'apt' -ParameterFilterRule '*'

        Remove-SudoPreferenceRule -All

        @(Get-SudoPreferenceRule -All) | Should -HaveCount 0
    }

    It 'Should remove duplicate matches without skipping shifted indexes' {
        $null = $script:SudoPreferenceRules.Add(@{
            Executable = 'dpkg'; ParameterFilterRule = '*'; Sudo = $true; SudoAs = $null
        })
        $null = $script:SudoPreferenceRules.Add(@{
            Executable = 'apt'; ParameterFilterRule = '*'; Sudo = $true; SudoAs = $null
        })
        $null = $script:SudoPreferenceRules.Add(@{
            Executable = 'dpkg'; ParameterFilterRule = '*'; Sudo = $true; SudoAs = $null
        })

        @(Remove-SudoPreferenceRule -Executable 'dpkg' -ParameterFilterRule '*') |
            Should -HaveCount 2
        @(Get-SudoPreferenceRule -All) | Should -HaveCount 1
        (Get-SudoPreferenceRule -All).Executable | Should -Be 'apt'
    }

    It 'Should initialize an empty rule store when queried' {
        Remove-Variable -Name SudoPreferenceRules -Scope Script -ErrorAction Ignore

        { Get-SudoPreferenceRule -All } | Should -Not -Throw
        @(Get-SudoPreferenceRule -All) | Should -HaveCount 0
    }

    It 'Should preserve the language mode of a constrained caller script block' {
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
