using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class AppendMatch : LineParser
{
    [string] $Regex

    AppendMatch() : base ()
    {

    }

    AppendMatch([IDictionary]$Definition)
    {
        if ($Definition.Regex)
        {
            $this.Regex = $Definition.Regex
        }
    }

    [void] ParseLine([object] $Line)
    {
        if ($this.Regex)
        {
            if ($Line -match $this.regex) {
                $MatchingLine = $matches[0]
            }
            else
            {
                $MatchingLine = ''
            }
        }
        else
        {
            $MatchingLine = $Line
        }

        if ([string]::IsNullOrEmpty($this.ObjectOutput) -or $this.ObjectOutput -isnot [string])
        {
            if ( -not [string]::IsNullOrEmpty($MatchingLine))
            {
                $this.ObjectOutput = $MatchingLine
            }
        }
        else
        {
            $this.ObjectOutput = $this.ObjectOutput + [Environment]::NewLine + $MatchingLine
        }
    }
}
