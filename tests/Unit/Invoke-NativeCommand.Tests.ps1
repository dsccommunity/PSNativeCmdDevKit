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

    It 'passes parameters as separate values' {
        Invoke-NativeCommand -Executable 'Test-NativeTarget' -Parameters @(
            'value with spaces'
            '; Set-Variable -Name Injected -Value $true -Scope Script'
        )

        $script:ReceivedParameters | Should -HaveCount 2
        $script:ReceivedParameters[0] | Should -Be 'value with spaces'
        $script:ReceivedParameters[1] |
            Should -Be '; Set-Variable -Name Injected -Value $true -Scope Script'
        Get-Variable -Name Injected -Scope Script -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }

    It 'does not evaluate the executable as PowerShell source' {
        {
            Invoke-NativeCommand -Executable (
                'Test-NativeTarget; Set-Variable -Name Injected -Value $true -Scope Script'
            )
        } | Should -Throw

        Get-Variable -Name Injected -Scope Script -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }
}
