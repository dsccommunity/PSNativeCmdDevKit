using namespace System.Collections
using namespace System.Collections.Specialized

class ObjectBuilder
{
    [string] $ApiVersion
    [string] $Kind
    [string] $Spec
    [OrderedDictionary] $Metadata = [ordered]@{}

    ObjectBuilder()
    {

    }

    ObjectBuilder([OrderedDictionary] $ApiDefinition)
    {
        $this.ApiVersion = $ApiDefinition.ApiVersion
        $this.Kind = $ApiDefinition.Kind
        $this.Spec = $ApiDefinition.Spec

        $ApiDefinition.keys.Where{$_ -notin @('ApiVersion','Kind','Spec') }.foreach{
            $this.Metadata.Add($_, $ApiDefinition[$_])
        }
    }

    static [object] BuildObject([string] $Definition)
    {

        if (Test-Path -Path $Definition)
        {
            $DefinitionContent = Get-Content -Raw -Path $Definition | ConvertFrom-Yaml -ordered -ErrorAction Stop
            # By default we expect a ConfigParser in a definition
            Write-Debug -Message "Keys in Definition: $($DefinitionContent.keys)"
            return [ObjectBuilder]::BuildObject('ConfigParser', $DefinitionContent)
        }
        else
        {
            # if it's not a valid path to a file, let's assume it's just a string.
            return [ObjectBuilder]::BuildObject('string', $Definition)
        }
    }

    static [object] BuildObject([string] $DefaultType, [string] $Definition)
    {
        return [ObjectBuilder]::BuildObject(
            [ordered]@{
                kind = $DefaultType
                spec = $Definition
            }
        )
    }

    static [Object] BuildObject([string] $DefaultType, [IDictionary] $Definition)
    {
        if (-not $Definition -contains 'kind') {
            Write-Debug "Dispatching specs as $DefaultType.`r`n $($Definition | Format-List -Property * | Out-String)"
            return [ObjectBuilder]::BuildObject(
                [ordered]@{
                    kind = $DefaultType
                    spec = $Definition
                }
            )
        }
        else {
            Write-Debug "Definition defines kind, dispatching."
            return [ObjectBuilder]::BuildObject($Definition)
        }
    }

    static [Object] BuildObject([IDictionary] $Definition)
    {
        $moduleString = ''
        $returnCode = ''
        $Action = ''
        $ExecuteCode = $null

        if ($Definition.Kind -eq 'invoke' -or $Definition.Kind -eq '&')
        {
            Write-Debug -Message "Trying to get the result of '$($definition.Spec)'"
            $ExecuteCode = "return [scriptblock]::Create(`$args[0]).Invoke()"
        }
        elseif ($Definition.Kind -match '\\')
        {

            $moduleName, $Action = $Definition.Kind.Split('\', 2)
            Write-Debug -Message "Module is '$moduleName'"
            if ($Action -match '\-') {
                $moduleString = "Import-Module $moduleName"
            }
            else {
                $moduleString = "using module $moduleName"
            }
        }
        else
        {
            $Action = $Definition.Kind
        }

        if ($ExecuteCode) {
            $returnCode = $ExecuteCode
        }
        elseif ($Action -match '\-')
        {
            # Function
            $functionName = $Action
            Write-Debug -Message "Calling funcion $functionName"
            $returnCode = "`$params = `$Args[0]`r`n ,($functionName @params)"
        }
        elseif ($Action -match '::')
        {
            # Static Method
            $className, $StaticMethod = $Action.Split('::', 2)
            $className = $className.Trim() -replace '^\[|\]$'
            $StaticMethod = $StaticMethod.Trim('\(\):')
            Write-Debug -Message "Calling static method '[$className]::$StaticMethod(`$spec)'"
            $returnCode = "return [$className]::$StaticMethod(`$args[0])"
        }
        else
        {
            # Class::New()
            $className = $Action
            Write-Debug -Message "Creating new [$className]"
            $returnCode = "return [$className]::new(`$args[0])"
        }

        $specObject = $Definition.spec
        $script = "$moduleString`r`n$returnCode"
        Write-Debug "ScriptBlock = {`r`n$script`r`n}"
        if ($ExecuteCode) {
            return [scriptblock]::Create($script).Invoke($specObject)
        }
        else
        {
            return [scriptblock]::Create($script).Invoke($specObject)[0]
        }
    }
}
