using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class ParserSection
{
    [YamlIgnoreAttribute()]
    # Name of the Section, should be the key for the section in the config.
    [string] $Name

    [object] $StaticValue

    # decribe how the section starts, usually with the first line, or when the
    # line input matches a given regex
    [string] $StartsWith        = $null     # FirstLine | Regex | FirstLine | null

    # store wether the section has started (in case StartsWith is set)
    [YamlIgnoreAttribute()]
    [bool] $SectionHasStarted = $false

    # Describes when the parser should move to the next section.
    [UntilClause] $Until        = 'NextSection' # AfterNumberOfLines | NextSectionStartsWithRegex | forever

    # Parser that can parse the output for the section.
    [LineParser] $Parser        = $null

    [YamlIgnoreAttribute()]
    [int]    $LineCounter       = 0
    [int]    $EmptyLineCounter  = 0

    [YamlIgnoreAttribute()]
    [OrderedDictionary] $SectionValue = [ordered]@{}

    [YamlIgnoreAttribute()]
    [object] $OutputObject = [ordered]@{}

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
        if (-not $this.SectionHasStarted)
        {
            if ($this.StartsWith -notin @('FirstLine'))
            {
                if ($Line -match $this.StartsWith)
                {
                    Write-Debug -Message "starting section as regex matches."
                    $this.SectionHasStarted = $true
                }
                else
                {
                    Write-Debug -Message "This section hasn't started yet."
                }
            }
            else
            {
                Write-Debug -Message "starting section, no regex required."
                $this.SectionHasStarted = $true
            }
        }

        if ($this.SectionHasStarted -and $this.Parser.ParseLine)
        {
            $this.OutputObject = $this.Parser.ParseLine($Line)
        }
    }

    [object] GetParsedObject()
    {
        if ($this.Parser.GetParsedObject)
        {
            return $this.Parser.GetParsedObject()
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

        if ($Definition.keys -contains 'StaticValue')
        {
            Write-Debug -Message "Creating Static Value Section [$($this.Name)]."
            $this.StaticValue = $Definition.StaticValue
            $this.OutputObject = $this.StaticValue
            $this.Until =  [ObjectBuilder]::BuildObject('UntilClause', @{
                UntilRule = 'UseSameLine'
            })
        }
        elseif ($Definition.Until)
        {
            $this.Until = [ObjectBuilder]::BuildObject('UntilClause', $Definition.Until)
        }

        $this.Parser = foreach ($Parser in $Definition.Parser)
        {
            [ObjectBuilder]::BuildObject('AppendMatch', $Parser)
        }
    }
}
