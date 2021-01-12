function Get-ParsedOutput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]
        $Input,

        [string]
        $ParsingConfig
    )

    begin {
        try
        {
            $configParser = [ObjectBuilder]::BuildObject('ConfigParser', $ConfigParserPath)
        }
        catch
        {
            throw $_.Exception
        }
    }

    process {
        foreach ($Line in $Input)
        {
            # Write-Debug "output: '$_'"

            # Process the $_ (output line)
            $configParser.ParseLine($Line)
        }
    }

    end {
        Write-Debug -Message "************************"
        Write-Debug -Message "Reached the end of the Output."


        Write-Debug -Message "Terminating the ouptut parsing."
    }

}

# (choco list --help) | Get-ParsedOutput
