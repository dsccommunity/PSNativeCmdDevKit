function Get-ParsedOutput {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]
        $Input,

        [System.Collections.Specialized.OrderedDictionary]
        $ParsingConfig
    )

    begin {
        $sections = $ParsingConfig.sections
        $sectionKeys = [string[]]$sections.keys
        $sectionIndex = 0
        $outputLineNumber = -1
        $sectionLineCounters = @{}
        $previousSection = $null
        $parsedObject = [ordered]@{}
        $currentPropertyPath = ''
    }

    process {
        $Line | Foreach-Object {
            (($currentSection = $sections.$sectionIndex))
            $currentSectionName = $sectionKeys.$sectionIndex
            $OutputLineNumber++

            Write-Debug "[L#$OutputLineNumber] Processing line $OutputLineNumber "
            Write-Debug "output: '$_'"

            #Region evaluate section trigger to decide whether to move section or keep within the same
            if ([string]::IsNullOrWhiteSpace($_) -and $currentSection.Until -eq 'EmptyLine')
            {
                # Empty line & change section on empty line
                $sectionIndex++
                $previousSection = $currentSection
                $currentSection = $sections.$sectionIndex
                $currentSectionName = $sectionKeys.$sectionIndex
                Write-Debug "Moving to section $($currentSection.Name)"

            }
            elseif ($currentSection.Until -eq 'AfterNumberOfLines' )
            {
                # if there's no line counter for this section, initialize it to 0
                if (-not $sectionLineCounters.$currentSectionName)
                {
                    Write-Debug -Message "Creating Counter for '$currentSectionName' and set to 0."
                    $sectionLineCounters.$currentSectionName = 0
                }

                # Current section changes when we've processed a number of lines in this section
                if ($sectionLineCounters.$currentSectionName -ge $currentSection.NumberOfLines)
                {
                    # We've hit the number of lines for current section. Make it previous, move to next, set to 1
                    $sectionIndex++
                    $previousSection     = $currentSection
                    $previousSectionName = $currentSectionName
                    $currentSection      = $sections.$sectionIndex
                    $currentSectionName  = $sectionKeys.$sectionIndex
                    Write-Debug -Message "******`r`n**  Starting Section '$currentSectionName' after $($sectionLineCounters[$currentSectionName]) lines in section '$previousSectionName'"

                    # clean previous section counter, set current section counter to 1st line
                    $sectionLineCounters.$previousSectionName  = $null
                    $sectionLineCounters.$currentSectionName  = 1
                }
                else
                {
                    # increment number of lines in this section
                    #   Not reached the number configured, add 1 to the current section line counter
                    $sectionLineCounters[$currentSectionName]++
                    Write-Debug -Message "** '$currentSectionName' -- #L$($sectionLineCounters[$currentSectionName])"
                }
            }
            elseif ($currentSection.Until -eq 'NextSectionStartsWithRegex' -and $_ -match $sections.($sectionIndex+1).StartWith)
            {
                # detected we've reached a new section from the next section regex
                $sectionIndex++
                $previousSection     = $currentSection
                $previousSectionName = $currentSectionName
                $currentSection      = $sections.$sectionIndex
                $currentSectionName  = $sectionKeys.$sectionIndex
                Write-Debug -Message "******`r`n**  Starting Section '$currentSectionName' after $($sectionLineCounters[$currentSectionName]) lines in section '$previousSectionName'"

                # clean previous section counter, set current section counter to 1st line
                $sectionLineCounters.$previousSectionName  = $null
                $sectionLineCounters.$currentSectionName   = 1
            }
            else
            {
                # No trigger to switch to next section found, just keep counting lines for this section.
                ($sectionLineCounters.$currentSectionName)++
            }
            #endregion


            # Process the $_ (output line)

        }
    }

    end {
        [PSCustomObject]$ParsedObject
    }

}

# (choco list --help) | Get-ParsedOutput
