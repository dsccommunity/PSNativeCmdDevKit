using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ConfigParser : ParserSubSection
{
    [OrderedDictionary] $OutputGenerator = [ordered]@{}

    [YamlIgnoreAttribute()]
    [int] $SectionIndex = 0

    [YamlIgnoreAttribute()]
    [int] $outputLineNumber = -1

    [YamlIgnoreAttribute()]
    [hashtable] $SectionLineCounters = @{}

    [YamlIgnoreAttribute()]
    [Object] $previousSection = $null

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

    hidden [void] LoadSections([OrderedDictionary]$SectionDefinitions)
    {
        foreach ($SectionName in $SectionDefinitions.Keys) {
            $SectionDefinition = $SectionDefinitions[$SectionName]
            Write-Debug -Message "Adding section '$SectionName'."
            $this.Sections.Add(
                $SectionName,
                [ObjectBuilder]::BuildObject('ParserSection', $SectionDefinition)
            )
        }
    }

    [void] ParseLine([object] $line)
    {

    }

    [bool] ShouldMoveToNextSection()
    {

        return $false
    }

    [void] MoveToNextSection()
    {

    }

}
