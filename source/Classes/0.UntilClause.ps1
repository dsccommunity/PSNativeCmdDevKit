using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class UntilClause
{
    [string] $UntilRule
    [Nullable[System.Int32]] $NumberOfLines = $null
    [Nullable[System.Int32]] $NumberOfEmptyLines = $null

    UntilClause()
    {
        $this.UntilRule = 'NextSection'
    }

    UntilClause([string] $Definition)
    {
        if ($Definition -eq 'UseSameLine')
        {
            $this.UntilRule = 'UseSameLine'
        }
        elseif ($Definition -eq 'NextSection' -or [string]::IsNullOrEmpty($Definition))
        {
            $this.UntilRule = 'NextSection'
        }
        elseif ($Definition -in @('EmptyLine','NumberOfEmptyLines','AfterNumberOfEmptyLines'))
        {
            $this.NumberOfEmptyLines = 1
            $this.UntilRule = 'AfterNumberOfEmptyLines'
        }
        elseif ($Definition -in @('NumberOfLines','AfterNumberOfLines'))
        {
            $this.NumberOfLines = 1
            $this.UntilRule = "AfterNumberOfLines"
        }
        else
        {
            $this.UntilRule = 'NextSection'
        }
    }

    UntilClause([IDictionary]$Definition)
    {
        if ($Definition.UntilRule -eq 'UseSameLine')
        {
            $this.UntilRule = 'UseSameLine'
        }
        elseif ($Definition.UntilRule -eq 'NextSection')
        {
            $this.UntilRule = 'NextSection'
        }
        elseif (
            $Definition.UntilRule -in @('EmptyLine','NumberOfEmptyLines','AfterNumberOfEmptyLines') -or
            $Definition.keys -contains 'NumberOfEmptyLines'
        )
        {
            $this.UntilRule = 'AfterNumberOfEmptyLines'
            if ($Definition.NumberOfEmptyLines)
            {
                $this.NumberOfEmptyLines = $Definition.NumberOfEmptyLines
            }
            else
            {
                $this.NumberOfEmptyLines = 1
            }
        }
        elseif (
            $Definition.UntilRule -in @('NumberOfLines','AfterNumberOfLines') -or
            $Definition.keys -contains 'NumberOfLines'
        )
        {
            $this.UntilRule = "AfterNumberOfLines"
            if ($Definition.NumberOfLines)
            {
                $this.NumberOfLines = $Definition.NumberOfLines
            }
            else
            {
                $this.NumberOfLines = 1
            }
        }
        else
        {
            $this.UntilRule = 'NextSection'
        }
    }

    [bool] isUntilClauseReachedForSection([ParserSection] $Section)
    {
        if ($this.UntilRule -eq 'UseSameLine')
        {
            return $true
        }
        elseif (
            ($null -ne $this.NumberOfLines -and $Section.LineCounter -ge $this.NumberOfLines) -or
            ($null -ne $this.NumberOfEmptyLiness -and $Section.EmptyLineCounter -ge $this.NumberOfEmptyLines)
        )
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    [string] ToString()
    {
        return ($this | ConvertTo-Yaml -Options EmitDefaults)
    }
}
