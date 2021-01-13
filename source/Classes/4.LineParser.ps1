using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class LineParser
{
    [YamlIgnoreAttribute()]
    hidden [Object] $ObjectOutput = [ordered]@{}
    [string] $Transform

    LineParser()
    {
        # throw "This class is not meant to be instantiated directly."
    }

    [void] ParseLine([object] $Line)
    {
        throw "this method must be overriden by the Parser implementation."
    }

    [void] ResetOuputObject()
    {
        $this.ObjectOutput = [Ordered]@{}
    }

    [Object] GetParsedObject()
    {
        if (-not $this.Transform)
        {
            return $this.ObjectOutput
        }
        elseif ($this.Transform -match '^\{(?<scriptblock>[\W\w]*)\}$')
        {
            return [scriptblock]::Create($Matches.scriptblock).Invoke($this.ObjectOutput)
        }
        else
        {
            $TransformerParams = @{
                TypeTransformerDefinition = $this.Transform
                ObjectToTransform = $this.ObjectOutput
            }

            return (Get-TransformedObject @TransformerParams)
        }
    }
}
