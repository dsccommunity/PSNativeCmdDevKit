using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ParserSubSection : ParserSection
{
    [OrderedDictionary] $Sections = [ordered]@{}

    ParserSubSection() : base ()
    {
        Write-Debug -Message "Calling [ParserSubSection] Parameterless constructor"
    }

    ParserSubSection([IDictionary] $Definition)
    {
        Write-Debug -Message "Calling SubSection constructor."
        Write-Debug -Message "Keys: $($Definition.Keys -join ', ')."
        $this.LoadParserSection($Definition)

        if ($Definition.Sections)
        {
            $this.LoadParserSubSections($Definition.Sections)
        }
    }

    hidden [void] LoadParserSubSections([OrderedDictionary]$SectionDefinitions)
    {
        foreach ($SectionName in $SectionDefinitions.Keys) {
            # if the section definition is a scalar,
            # make it a static value.
            if ($SectionDefinitions[$SectionName].GetType() -in @([string],[bool],[int]))
            {
                $SectionDefinition = [ordered]@{
                    StaticValue = $SectionDefinitions[$SectionName]
                    Name = $SectionName
                    Until = @{
                        UntilRule = 'UseSameLine'
                    }
                }
            }
            else
            {
                $SectionDefinition = $SectionDefinitions[$SectionName]
            }

            if ($SectionDefinition.Keys -contains 'spec')
            {
                $SectionDefinition['spec']['Name'] = $SectionName
            }
            else
            {
                $SectionDefinition['Name'] = $SectionName
            }

            Write-Debug -Message "Adding section '$SectionName', with keys: $($SectionDefinition.Keys -join ', ')."
            $this.Sections.Add(
                $SectionName,
                [ObjectBuilder]::BuildObject('ParserSection', $SectionDefinition)
            )
        }
    }
}
