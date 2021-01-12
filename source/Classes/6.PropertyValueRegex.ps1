using namespace System.Collections
using namespace System.Collections.Specialized
using namespace YamlDotNet.Serialization

class PropertyValueRegex
{
    [string] $Pattern
    [bool] $CaseSensitive
    [bool] $AllowNullValue
    [bool] $AllMatches

    PropertyValueRegex()
    {

    }

    PropertyValueRegex([string] $Regex)
    {
        $this.CaseSensitive = $false
        $this.AllowNullValue = $true
        $this.AllMatches = $true
        $this.Pattern = $Regex
    }

    PropertyValueRegex([IDictionary] $Definition)
    {
        Write-Debug -Message "Processing Definition $($Definition | ConvertTo-Yaml -Options emitDefault)."

        if ($true -eq $Definition.CaseSensitive)
        {
            $this.CaseSensitive = $true
        }
        else
        {
            $this.CaseSensitive = $false
        }

        if ($true -eq $Definition.AllowNullValue)
        {
            $this.AllowNullValue = $true
        }
        else
        {
            $this.AllowNullValue = $false
        }

        if ($true -eq $Definition.AllMatches)
        {
            $this.AllMatches = $true
        }
        else
        {
            $this.AllMatches = $false
        }

        if ($Definition.Pattern -as [regex])
        {
            $this.Pattern = $Definition.Pattern
        }
        else
        {
            throw 'The Regex pattern is missing.'
        }
    }
}
