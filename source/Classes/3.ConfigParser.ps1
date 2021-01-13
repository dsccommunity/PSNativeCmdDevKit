using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ConfigParser : ParserSubSection
{
    [OrderedDictionary] $OutputGenerator = [ordered]@{}

    [YamlIgnoreAttribute()]
    [int] $SectionIndex = 0

    [YamlIgnoreAttribute()]
    [int] $OutputLineNumber = -1

    [YamlIgnoreAttribute()]
    [hashtable] $SectionLineCounters = @{}

    [YamlIgnoreAttribute()]
    hidden [ParserSection] $previousSection

    ConfigParser()
    {
        Write-Debug -Message "Calling [ConfigParser] parameterless constructor"
    }

    ConfigParser([string]$Path)
    {
        if ((Test-Path -Path $Path))
        {
            $Definition = Get-Content -Raw -Path $Path | ConvertFrom-Yaml -ordered
            if ($Definition) {
                $this.LoadParserSection($Definition)

                if ($Definition.Sections.keys)
                {
                    $this.LoadParserSubSections($Definition.Sections)
                }

                if ($Definition.'OutputGenerator'.keys)
                {
                    $this.LoadOuputGenerator($Definition.OutputGenerator)
                }
            }
        }
    }

    ConfigParser([IDictionary]$Definition)
    {
        $this.LoadParserSection($Definition)

        if ($Definition.Sections.keys)
        {
            $this.LoadParserSubSections($Definition.Sections)
        }

        if ($Definition.'OutputGenerator'.keys)
        {
            $this.LoadOuputGenerator($Definition.OutputGenerator)
        }
    }

    hidden LoadConfigParserDefinition([IDictionary] $Definition)
    {
        if ($Definition.'OutputGenerator'.keys)
        {
            $this.LoadOuputGenerator($Definition.OutputGenerator)
        }
    }

    hidden [void] LoadOuputGenerator([OrderedDictionary]$OutputGeneratorDefinitions)
    {
        foreach ($outputGeneratorName in $OutputGeneratorDefinitions.keys) {
            $outputItem = $OutputGeneratorDefinitions[$outputGeneratorName]
            $this.OutputGenerator.Add(
                $outputGeneratorName,
                [ObjectBuilder]::BuildObject('string', $outputItem)
            )
        }
    }

    [void] ParseLine([object] $Line)
    {
        $this.OutputLineNumber++
        Write-Debug -Message "[L#$($this.OutputLineNumber)] Processing line:`r`n$Line"

        do
        {
            if ($this.ShouldMoveToNextSection($Line))
            {
                Write-Debug -Message "Moving to next section."
                $this.MoveToNextSection()
            }

            if ($this.getCurrentSection())
            {
                Write-Debug -Message "Parsing line #$($this.OutputLineNumber) with Section $($this.getCurrentSectionName())'s method."
                if ([string]::IsNullOrEmpty($Line.Trim()))
                {
                    $this.getCurrentSection().EmptyLineCounter++
                }
                else
                {
                    $this.getCurrentSection().ParseLine($Line)
                }

                $this.IncrementCurrentSectionCounter()
            }
        }
        while ($this.getCurrentSection().Until.UntilRule -eq 'UseSameLine')
    }

    [ParserSection] getCurrentSection()
    {
        return $this.Sections[$this.SectionIndex]
    }

    [string] getCurrentSectionName()
    {
        return $this.getCurrentSection().Name
    }

    [bool] ShouldMoveToNextSection([object] $Line)
    {
        if ($this.getCurrentSection().Until.UntilRule -eq 'UseSameLine' -and $this.getCurrentSection().LineCounter -gt 0)
        {
            return $true
        }
        elseif (
            $this.getCurrentSection().Until.UntilRule -eq 'AfterNumberOfEmptyLines' -and
            $this.getCurrentSection().Until.isUntilClauseReachedForSection($this.getCurrentSection())
        )
        {
            Write-Debug -Message "[$($this.getCurrentSectionName())] Empty Line #$($this.getCurrentSection().EmptyLineCounter) found, moving off section."
            return $true
        }
        elseif (
            $this.getCurrentSection().Until.UntilRule -eq 'AfterNumberOfLines' -and
            $this.getCurrentSection().Until.isUntilClauseReachedForSection($this.getCurrentSection())
        )
        {
            Write-Debug -Message "[$($this.getCurrentSectionName())] Reached $($this.getCurrentSection().LineCounter) lines, moving off."
            return $true
        }
        elseif (
            $this.getCurrentSection().Until.UntilRule -eq 'NextSection' -and
            $this.isNextSectionStarting($Line)
        )
        {
            Write-Debug -Message "[$($this.getCurrentSectionName())] End of Section, next section is starting."
            return $true
        }
        else
        {
            Write-Debug -Message "No need to move to next section."
            return $false
        }
    }

    [bool] isNextSectionStarting([object]$Line)
    {
        $nextSection = $this.Sections[($this.SectionIndex+1)]
        if ($nextSection -and $Line -match $nextSection.StartsWith)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    [void] IncrementCurrentSectionCounter()
    {
        if ($currentSection = $this.getCurrentSection()) {
            $currentSection.LineCounter++
        }
        else
        {
            Write-Verbose -Message "No section currently selected. Did you reach the end of your config?"
        }
    }

    [void] MoveToNextSection()
    {
        # before moving off, return the section's object and add to parent output object
        $this.previousSection = $this.getCurrentSection()
        if ($this.previousSection)
        {
            Write-Debug -Message "Adding subkey $($this.previousSection.Name) to output object."
            $this.OutputObject[$this.previousSection.Name] = $this.previousSection.GetParsedObject()
        }

        # Reset the previousSection in case we need to get back to it (should probably be moved to an init() method upon entry)
        if ($this.previousSection)
        {
            $this.previousSection.OutputObject = [ordered]@{}
            $this.PreviousSection.LineCounter = 0
            $this.PreviousSection.EmptyLineCounter = 0
        }

        $this.SectionIndex++

        if ($this.getCurrentSection())
        {
            Write-Debug -Message "Moved to Section '$($this.getCurrentSectionName())'"
        }
    }

    [object] GetParsedObject()
    {
        return $this.OutputObject
    }
}
