using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ParserSection
{
    [YamlIgnoreAttribute()]
    [string] $Name

    [string] $StartsWith        = $null     # FirstLine | Regex | FirstLine | null
    [UntilClause] $Until        = 'NextSection' # AfterNumberOfLines | NextSectionStartsWithRegex | forever
    [string] $DoAfter           = 'MoveNext'    # stop | next | loop | "GOTO:ChocoVersion"
    [LineParser] $Parser        = $null

    [YamlIgnoreAttribute()]
    [int]    $LineCounter       = 0
    [int]    $EmptyLineCounter  = 0

    [YamlIgnoreAttribute()]
    [OrderedDictionary] $SectionValue = [ordered]@{}

    [YamlIgnoreAttribute()]
    [hashtable] $OutputObject = @{}

    # Constructor (empty)
    ParserSection ()
    {

    }

    # Constructor with a dict containing properties
    ParserSection ([IDictionary] $Definition) {
        $this.LoadParserSection($Definition)
    }

    # Getting the ParserSection to parse the line by sending
    # to the implemented parser to do the job.
    # Special sections (sub/loop) may override this behaviour.
    # The output of the parser is stored in the section's output object
    # by default, but the Parser can have custom handling of the object
    # creation (i.e. when building over multiple lines), and eventually the section can
    # call the getParsedObject if implemented on the Parser
    [void] ParseLine([Object] $Line)
    {
        $this.OutputObject = $this.Parser.ParseLine($Line)
    }

    [object] GetParsedObject()
    {
        if ($this.Parser.GetObject)
        {
            return $this.Parser.GetObject()
        }
        else
        {
            return $this.OutputObject
        }
    }

    hidden [void] LoadParserSection([OrderedDictionary] $Definition)
    {
        if ($Definition.Name)
        {
            $this.Name = $Definition.Name
        }

        if ($Definition.StartsWith)
        {
            $this.StartsWith = $Definition.StartsWith
        }

        if ($Definition.DoAfter)
        {
            $this.DoAfter = $Definition.DoAfter
        }

        if ($Definition.Until)
        {
            $this.Until = [ObjectBuilder]::BuildObject('UntilClause', $Definition.Until)
        }

        $this.Parser = foreach ($Parser in $Definition.Parser)
        {
            [ObjectBuilder]::BuildObject('ObjectMatch', $Parser)
        }
    }
}
