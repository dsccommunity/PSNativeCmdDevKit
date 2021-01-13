function Get-ParsedOutput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]
        $Input,

        [string]
        $ConfigParserPath,

        [int]
        $Skip = 0,

        [int]
        $First
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
        $LineCounter = -1
    }

    process {
        foreach ($Line in $Input)
        {
            $LineCounter++
            Write-Verbose -Message "[L#$($LineCounter)]:`r`n$Line"
            # Process the $_ (output line)
            if ($LineCounter -gt ($Skip - 1) -and (!$PSBoundParameters.ContainsKey('First') -or ($PSBoundParameters.ContainsKey('First') -and $LineCounter -lt $First)))
            {
                $configParser.ParseLine($Line)
            }
            else
            {
                Write-Verbose -Message "Line: $LineCounter | Skip: $Skip | First: $First"
            }

            # stream output object if configured
        }
    }

    end {
        Write-Debug -Message "************************"
        Write-Debug -Message "Reached the end of the Output."
        $configParser.MoveToNextSection() # to make sure we're out of the Section and object is complete
        $configParser.GetParsedObject()

        Write-Debug -Message "Terminating the ouptut parsing."
    }

}

# (choco list --help) | Get-ParsedOutput
