using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ParserSection
{
    [string] $Name
    [string] $StartWith     = $null     # FirstLine | Regex | FirstLine | null
    [string] $Until         = 'forever' # AfterNumberOfLines | NextSectionStartsWithRegex | forever
    [string] $DoAfter       = 'MoveNext'    # stop | next | loop | "GOTO:ChocoVersion"
    [int]    $NumberOfLines = 0
    [Object] $Parser        = $null
    # [string] $AllowedType   =
    [YamlIgnoreAttribute()]
    [OrderedDictionary] $SectionValue = [ordered]@{}

    ParserSection ()
    {

    }

    ParserSection ([IDictionary] $Definition) {
        $this.LoadParserSection($Definition)
    }

    hidden [void] LoadParserSection([OrderedDictionary] $Definition)
    {
        if ($Definition.StartWith)
        {
            $this.StartWith = $Definition.StartWith
        }

        if ($Definition.Until)
        {
            $this.Until = $Definition.Until
        }

        if ($Definition.DoAfter)
        {
            $this.DoAfter = $Definition.DoAfter
        }

        if ($Definition.NumberOfLines)
        {
            $this.NumberOfLines = $Definition.NumberOfLines
        }

        $this.Parser = foreach ($Parser in $Definition.Parser)
        {
            [ObjectBuilder]::BuildObject('ObjectMatch', $Parser)
        }
    }
}
