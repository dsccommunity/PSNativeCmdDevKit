using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ParserSubSection : ParserSection
{
    [OrderedDictionary] $Sections = [ordered]@{}

    ParserSubSection() : base()
    {
        Write-Debug -Message "Calling [ParserSubSection] Parameterless constructor"
    }

    ParserSubSection([IDictionary] $Definition) : base ([OrderedDictionary] $Definition)
    {
        Write-Debug -Message "Calling SubSection constructor."
        Write-Debug -Message "Keys: $($Definition.Keys -join ', ')"
        $this.LoadParserSection($Definition)

        if ($Definition.Sections)
        {
            $this.LoadParserSubSections($Definition.Sections)
        }
    }

    hidden [void] LoadParserSubSections([OrderedDictionary]$SectionDefinitions)
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
}
