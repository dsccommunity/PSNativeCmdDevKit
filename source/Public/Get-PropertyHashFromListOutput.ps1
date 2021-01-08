function Get-PropertyHashFromListOutput
{
    [CmdletBinding(DefaultParameterSetName = 'AddExtraPropertiesUnderKey')]
    [OutputType([hashtable])]
    param
    (
        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [Parameter(ParameterSetName = 'DiscardExtraProperties', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [AllowNull()]
        # Output from a command, typically the result of Invoke-LinuxCommand.
        # Error records will be handled by the scriptblock in -ErrorHandling parameter.
        # The latter defaults to send the error record to Write-Error.
        [Object]
        $Output,

        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey')]
        [Parameter(ParameterSetName = 'DiscardExtraProperties')]
        # Number of output lines (not STDERR) to ignore
        # before processing the output.
        [int]
        $SkipOutputLines = 0,

        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey')]
        [Parameter(ParameterSetName = 'DiscardExtraProperties')]
        # Regex with 'property' & 'val' Named groups
        # of a string to extract an hashtable key/value pair from a string.
        [regex]
        $Regex = '^\s*(?<property>[\w-\s]*):\s*(?<val>.*)',

        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey')]
        [Parameter(ParameterSetName = 'DiscardExtraProperties')]
        # List of property names allowed to be parsed.
        # Default to '*' for all properties, otherwise the parsed properties
        # not listed here will either be discarded if -DiscardExtraProperties is set
        # or will be added to a hashtable under the key named $AddExtraPropertiesAsKey.
        [string[]]
        $AllowedPropertyName = '*',

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DiscardExtraProperties')]
        # When only a limited number of Property named is allowed using -AllowedPropertyName
        # parameter, the extra properties will be discarded.
        [switch]
        $DiscardExtraProperties,

        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey')]
        # When only a limited number of Property named is allowed using -AllowedPropertyName
        # parameter, the extra properties will be added under the `$property[$AddExtraPropertiesAsKey]`
        # hash. For instance, `$property['ExtraProperties']['NotAllowedPropertyName'] = $ParsedValue`
        [string]
        $AddExtraPropertiesAsKey = 'ExtraProperties',

        [Parameter(ParameterSetName = 'AddExtraPropertiesUnderKey')]
        [Parameter(ParameterSetName = 'DiscardExtraProperties')]
        # When the output of a native command has had its `STDERR` redirected
        # using `2>&1`, we'll send the ErrorRecords (output from STDERR) to
        # this scriptblock. By default: `$errorRecord | &{ Write-Error $_}`.
        [scriptblock]
        $ErrorHandling = { Write-Error $_ }
    )

    begin
    {
        $lineNumber = 0
        $SkipOutputLines = $SkipOutputLines -1 # re-indexing starting at 0
        $properties = @{}
        if (-not $DiscardExtraProperties.isPresent)
        {
            $properties[$AddExtraPropertiesAsKey] = @{}
        }
    }

    process
    {
        foreach ($line in $Output)
        {
            if ($line -isnot [System.Management.Automation.ErrorRecord] -and $lineNumber -le $SkipOutputLines) {
                Write-Debug "Skipping Output Line [$lineNumber]: $line"
                $lineNumber++
                continue
            }

            Write-Debug "Output Line [$lineNumber]: $line"
            if ($line -is [System.Management.Automation.ErrorRecord])
            {
                $line | &$ErrorHandling
            }
            elseif ($line -match $Regex)
            {
                $propertyName = $Matches.property.replace('-','').replace(' ','')
                if ($AllowedPropertyName -contains '*' -or $AllowedPropertyName -contains $propertyName)
                {
                    $properties.Add($propertyName, $Matches.val)
                }
                else
                {
                    if (-not $DiscardExtraProperties.isPresent)
                    {
                        Write-Debug " Adding Property '$propertyName' to $AddExtraPropertiesAsKey"
                        $properties[$AddExtraPropertiesAsKey].Add($propertyName, $Matches.val)
                    }
                }

                $lastProperty = $propertyName
                $lineNumber++
            }
            else
            {
                if (-not $lastProperty)
                {
                    Write-Verbose $line
                }
                elseif ($AllowedPropertyName -contains '*' -or $AllowedPropertyName -contains $lastProperty)
                {
                    Write-Debug "  Adding second line to property $lastProperty"
                    $properties[$lastProperty] += "`n" + $line.TrimEnd()
                }
                else
                {
                    $properties[$AddExtraPropertiesAsKey][$lastProperty] += $line.Trim()
                }
                $lineNumber++
            }
        }
    }

    end
    {
        if ($properties[$AddExtraPropertiesAsKey].Count -eq 0)
        {
            Write-Debug "No Extra properties where found, removing unnecessary key '$AddExtraPropertiesAsKey'"
            $properties.Remove($AddExtraPropertiesAsKey)
        }

        $properties
    }
}
