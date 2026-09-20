Describe 'Get-PropertyHashFromListOutput' {
    BeforeAll {
        $script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . "$script:ProjectRoot\source\Public\Get-PropertyHashFromListOutput.ps1"
    }

    It 'Should parse property names and normalize spaces and hyphens' {
        $result = @(
            'Distributor ID: Ubuntu'
            'Release-Name: Noble'
        ) | Get-PropertyHashFromListOutput

        $result.DistributorID | Should -Be 'Ubuntu'
        $result.ReleaseName | Should -Be 'Noble'
        $result.ContainsKey('ExtraProperties') | Should -BeFalse
    }

    It 'Should append continuation lines to the previous property' {
        $result = @(
            'Description: First line'
            ' second line'
        ) | Get-PropertyHashFromListOutput

        $result.Description | Should -Be "First line`n second line"
    }

    It 'Should collect disallowed properties under the configured key' {
        $result = @(
            'Name: PowerShell'
            'Version: 7.6'
        ) | Get-PropertyHashFromListOutput `
            -AllowedPropertyName 'Name' `
            -AddExtraPropertiesAsKey 'Additional'

        $result.Name | Should -Be 'PowerShell'
        $result.Additional.Version | Should -Be '7.6'
    }

    It 'Should append continuation lines to an extra property' {
        $result = @(
            'Name: PowerShell'
            'Description: First line'
            ' second line'
        ) | Get-PropertyHashFromListOutput -AllowedPropertyName 'Name'

        $result.ExtraProperties.Description | Should -Be 'First linesecond line'
    }

    It 'Should discard disallowed properties and their continuation lines' {
        {
            $script:discardedResult = @(
                'Name: PowerShell'
                'Description: First line'
                ' second line'
            ) | Get-PropertyHashFromListOutput `
                -AllowedPropertyName 'Name' `
                -DiscardExtraProperties
        } | Should -Not -Throw

        $script:discardedResult.Name | Should -Be 'PowerShell'
        $script:discardedResult.ContainsKey('Description') | Should -BeFalse
        $script:discardedResult.ContainsKey('ExtraProperties') | Should -BeFalse
    }

    It 'Should support a custom regular expression' {
        $result = 'Name=PowerShell' |
            Get-PropertyHashFromListOutput -Regex '^(?<property>[^=]+)=(?<val>.*)$'

        $result.Name | Should -Be 'PowerShell'
    }

    It 'Should pass error records to the error handler' {
        $script:handledError = $null
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]::new('native stderr'),
            'NativeError',
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )

        $result = @(
            $errorRecord
            'Name: PowerShell'
        ) | Get-PropertyHashFromListOutput -ErrorHandling {
            $script:handledError = $_
        }

        [object]::ReferenceEquals($script:handledError, $errorRecord) |
            Should -BeTrue
        $result.Name | Should -Be 'PowerShell'
    }

    It 'Should ignore non-property lines before the first property' {
        $result = @(
            'native command heading'
            'Name: PowerShell'
        ) | Get-PropertyHashFromListOutput

        $result.Keys | Should -Contain 'Name'
        $result.Values | Should -Not -Contain 'native command heading'
    }
}