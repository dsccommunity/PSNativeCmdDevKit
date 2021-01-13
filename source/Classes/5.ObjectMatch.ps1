class ObjectMatch : LineParser
{
    # Regex with Named groups to match the Line with
    # and extract properties
    [string] $Regex

    # Properties to extract and to order
    [string[]] $Properties

    # Definition of transformation of the parsed object if any.
    [string] $Transform

    ObjectMatch()
    {
        Write-Debug -Message "Calling ObjectMatch parameterless constructor."
    }

    ObjectMatch([hashtable] $Definition)
    {
        $this.Regex      = $Definition.Regex
        $this.Properties = $Definition.Properties
        $this.Transform  = $Definition.Transform
    }

    [void] ParseLine([object] $Line)
    {
        if ($line -match $this.Regex)
        {
            Write-Debug -Message "Line matches '$($this.Regex)'."
            # if Properties, then you need to order them
            if ($this.Properties)
            {
                $this.Properties.ForEach{
                    $this.ObjectOutput.Add($_, $Matches.$_)
                }
            }
            else
            {
                # No order required, use $Matches
                $this.ObjectOutput = $Matches.Clone()
                $this.ObjectOutput.remove(0)
            }
        }
        else
        {
            Write-Debug -Message "Line did not match the regex: '$($this.Regex)'."
        }
    }
}
