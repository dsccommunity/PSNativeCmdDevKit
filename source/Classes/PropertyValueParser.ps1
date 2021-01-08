using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class PropertyValueParser
{
    [string[]] $AllowedPropertyName
    [ExtraPropertyHandling] $ExtraProperty
    [string] $ExtraPropertyName
    [LineNotMatchedHandling] $LineNotMatched
    [PropertyValueRegex[]] $Regexes
    [string] $Transform
    hidden [OrderedDictionary] $Object = [ordered]@{}

    PropertyValueParser([IDictionary]$Definition)
    {

        $this.AllowedPropertyName = $Definition.AllowedPropertyName
        $this.ExtraProperty       = $Definition.ExtraProperty
        $this.LineNotMatched      = $Definition.LineNotMatched
        Write-Debug -Message "Number of Regexes: $($Definition.Regexes.count)."
        $this.Regexes = foreach ($Regex in $Definition.Regexes)
        {
            Write-Debug -Message "Adding $($Regex | Format-Table -Autosize | Out-String)."
            [PropertyValueRegex]::new($Regex)
        }

        if ([string]::IsNullOrEmpty($Definition.ExtraPropertyName))
        {
            $this.ExtraPropertyName = 'ExtraProperties'
        }
        else
        {
            $this.ExtraPropertyName = $Definition.ExtraPropertyName
        }

        $this.Transform = $Definition.Transform
    }

    [void] ParseLine($line)
    {
        # try each regex in order and if it matches
        # either:
        #   add Property/Value to $this.object
        #   add namedgroupname/value to $this.Object
        $lineMatched = $false
        foreach ($regex in $this.Regexes)
        {
            $PropertyName = ''
            # if $regex.NamedGroupAsPropertyName = $true
            $MatchInfo = $line | Select-String -Pattern $regex.Pattern -CaseSensitive:$regex.CaseSensitive -AllMatches:$regex.AllMatches
            if ($MatchInfo)
            {
                Write-Debug -Message "line: {$line} matched {$($regex.pattern)."
                $lineMatched = $true
            }

            foreach ($Matches in $MatchInfo.Matches.Groups.Captures)
            {
                # TODO
                if ($PropertyName -and $Matches.Name -eq 'Value')
                {
                    $this.AddPropertyToObject($PropertyName, $Matches.Value)
                    Write-Debug -Message "Adding property '$($PropertyName)' with value '$($Matches.Value)'"
                    $PropertyName = ''
                }
                elseif ($Matches.Name -eq 'Property')
                {
                    if ($PropertyName -and $regex.AllowNullValue)
                    {
                        Write-Debug -Message "Property '$PropertyName' is `$null"
                        $this.AddPropertyToObject($PropertyName, $null)
                    }

                    $PropertyName = $Matches.Value
                }
                elseif ($Matches.Name -notin @('property','0','value'))
                {
                    $this.AddPropertyToObject($Matches.Name, $Matches.Value)
                }
                else
                {
                    Write-Debug "Discarding Matches $($Matches.Name) with value $($Matches.Value)"
                }
            }

            if ($lineMatched -and $regex.Break) {
                # stop processing further regex
                Write-Debug -Message "Break found, stop processing regex for this line."
                break
            }
        }

        if (-not $lineMatched) {
            # discard | AppendToPreviousPropertyAsNewLine | Verbose | Debug
            switch ($this.LineNotMatched)
            {
                [LineNotMatchedHandling]::Verbose { Write-Verbose -Message $line}

                [LineNotMatchedHandling]::Debug { Write-Debug -Message $line}

                [LineNotMatchedHandling]::AppendToPreviousProperty {
                    $this.AddToLastProperty($line)
                }

                [LineNotMatchedHandling]::Discard { }

                Default { Write-Debug -Message $line}

            }
        }
    }

    [void] AddPropertyToObject ($PropertyName,$Value)
    {
        if ($PropertyName -in $this.AllowedPropertyName)
        {
            Write-Debug -Message "Adding $PropertyName with value $Value"
            $this.object.add($PropertyName, $Value)
        }
        elseif ($this.ExtraProperty -ne [ExtraPropertyHandling]::Discard)
        {
            if ($this.ExtraProperty -eq [ExtraPropertyHandling]::Add -and
                $this.Object.Keys -notcontains $PropertyName)
            {
                Write-Debug -Message "Adding $PropertyName with value $Value"
                $this.Object.Add($PropertyName,$Value)
            }
            elseif ($this.ExtraProperty -eq [ExtraPropertyHandling]::AddUnderKey)
            {
                if ($this.ExtraPropertyName -and $this.object.Keys -notcontains $this.ExtraPropertyName)
                {
                    $this.object.add($this.ExtraPropertyName,[ordered]@{})
                }

                if ($this.object.($this.ExtraPropertyName).keys -notcontains $PropertyName)
                {
                    Write-Debug -Message "Adding under $($this.ExtraPropertyName) property $PropertyName, value $Value"
                    $this.object.($this.ExtraPropertyName).Add($PropertyName,$Value)
                }
            }
        }
        else
        {
            Write-Debug -Message "Discarding $PropertyName with value $Value"
        }
    }

    [void] AddToLastProperty($value)
    {

    }

    [Object] GetObject()
    {
        if (-not $this.Transform)
            {
                return $this.object
            }
            elseif ($this.Transform -match '^\{(?<scriptblock>[\W\w]*)\}$')
            {
                return [scriptblock]::Create($Matches.scriptblock).Invoke($this.object)
            }
            else
            {
                $TransformerParams = @{
                    TransformerDefinition = $this.Transform
                    ObjectToTransform = $this.object
                }

                return (Get-TransformedObject @TransformerParams)
            }
    }
}
