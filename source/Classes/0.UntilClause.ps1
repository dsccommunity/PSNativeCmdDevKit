using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class UntilClause
{
    [string] $UntilRule = 'NextSection'
    [Nullable[System.Int32]] $NumberOfLines = $null
    [Nullable[System.Int32]] $NumberOfEmptyLines = $null

    UntilClause()
    {
        $this.UntilRule = 'NextSection'
    }

    UntilClause([string] $Definition)
    {
        if ($Definition -eq 'NextSection' -or [string]::IsNullOrEmpty($Definition))
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
        if ($Definition.keys -contains 'NumberOfLines')
        {
            $this.UntilRule = 'AfterNumberOfLines'
            $this.NumberOfLines = $Definition.NumberOfLines
        }

        if ($Definition.keys -contains 'NumberOfEmptyLines')
        {
            $this.UntilRule = 'AfterNumverOfEmptyLines'
            $this.NumberOfEmptyLines = $Definition.NumberOfEmptyLines
        }
    }

    [bool] isUntilClauseReachedForSection([ParserSection] $Section)
    {
        if (
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

}
