Describe 'Invoke-NativeCommand' {
    BeforeAll {
        $script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . "$script:ProjectRoot\source\Public\Get-SudoPreference.ps1"
        . "$script:ProjectRoot\source\Public\Invoke-NativeCommand.ps1"
    }

    BeforeEach {
        $script:ReceivedParameters = $null
        function Test-NativeTarget {
            $script:ReceivedParameters = $args
        }
    }

    AfterEach {
        Remove-Item -Path Function:\Test-NativeTarget -ErrorAction SilentlyContinue
    }

    It 'Should pass parameters as separate values' {
        Invoke-NativeCommand -Executable 'Test-NativeTarget' -Parameters @(
            'value with spaces'
            '; Set-Variable -Name Injected -Value $true -Scope Script'
        )

        $script:ReceivedParameters | Should -HaveCount 2
        $script:ReceivedParameters[0] | Should -Be 'value with spaces'
        $script:ReceivedParameters[1] |
            Should -Be '; Set-Variable -Name Injected -Value $true -Scope Script'
        Get-Variable -Name Injected -Scope Script -ErrorAction Ignore |
            Should -BeNullOrEmpty
    }

    It 'Should not evaluate the executable as PowerShell source' {
        {
            Invoke-NativeCommand -Executable (
                'Test-NativeTarget; Set-Variable -Name Injected -Value $true -Scope Script'
            )
        } | Should -Throw

        Get-Variable -Name Injected -Scope Script -ErrorAction Ignore |
            Should -BeNullOrEmpty
    }

    It 'Should use an applicable sudo preference on Unix' -Skip:(-not ($IsLinux -or $IsMacOS)) {
        $script:ReceivedSudoParameters = $null
        function sudo {
            $script:ReceivedSudoParameters = $args
        }

        $script:SudoPreferenceRules = [System.Collections.ArrayList]::new()
        $null = $script:SudoPreferenceRules.Add(@{
            Executable          = 'native-tool'
            ParameterFilterRule = '*'
            Sudo                = $true
            SudoAs              = 'service-user'
        })

        Invoke-NativeCommand -Executable 'native-tool' -Parameters '--version'

        $script:ReceivedSudoParameters | Should -HaveCount 4
        $script:ReceivedSudoParameters[0] | Should -Be '-u'
        $script:ReceivedSudoParameters[1] | Should -Be 'service-user'
        $script:ReceivedSudoParameters[2] | Should -Be 'native-tool'
        $script:ReceivedSudoParameters[3] | Should -Be '--version'
    }
}
