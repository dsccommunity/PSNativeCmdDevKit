class ObjectMatch
{
    # Regex with Named groups to match the Line with
    # and extract properties
    [Regex] $Regex

    # Properties to extract and to order
    [string[]] $Properties

    # Definition of transformation of the parsed object if any.
    [string] $Transform

    ObjectMatch([hashtable] $Definition)
    {
        $this.Regex      = $Definition.Regex
        $this.Properties = $Definition.Properties
        $this.Transform  = $Definition.Transform
    }

    [Object] GetObject($Line)
    {
        if ($line -match $this.Regex)
        {
            # if Properties, then you need to order them
            if ($this.Properties)
            {
                $object = [Ordered]@{}
                $this.Properties.ForEach{
                    $object.Add($_, $Matches.$_)
                }
            }
            else
            {
                # No order required, use $Matches
                $Matches.remove(0)
                $object = $Matches.Clone()
            }

            # If no Transform needed, return as-is
            if (-not $this.Transform)
            {
                return $object
            }
            elseif ($this.Transform -match '^\{(?<scriptblock>[\W\w]*)\}$')
            {
                return [scriptblock]::Create($Matches.scriptblock).Invoke($object)
            }
            else
            {
                $TransformerParams = @{
                    TransformerDefinition = $this.Transform
                    ObjectToTransform = $object
                }

                return (Get-TransformedObject @TransformerParams)
            }
        }
        else
        {
            return $null
        }
    }
}
