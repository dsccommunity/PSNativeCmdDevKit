function Get-TransformedObject
{
    [CmdletBinding()]
    [OutputType([Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $TypeTransformerDefinition,

        [Parameter(Mandatory = $true)]
        [Object]
        $ObjectToTransform
    )

    $moduleString = ''
    # Transforming the "Type" to [CastingType]$_, module\Get-Function $_, [class]::GetStatic($_)
    if ($TypeTransformerDefinition -match '\\')
    {
        $moduleName, $Transformer = $TypeTransformerDefinition.Split('\', 2)
        Write-Debug -Message "Module is '$moduleName'"
        if ($Transformer -match '\-')
        {
            $moduleString = "Import-Module $moduleName"
        }
        else
        {
            $moduleString = "using module $moduleName"
        }
    }
    else
    {
        $Transformer = $TypeTransformerDefinition
    }

    if ($Transformer -match '\-')
    {
        # Function
        $functionName = $Transformer
        Write-Debug -Message "Calling funcion $functionName"
        $returnCode = "`$params = `$Args[0]`r`n ,($functionName @params)"
    }
    elseif ($Transformer -match '::')
    {
        # Static Method
        $className, $staticMethod = $Transformer.Split('::', 2)
        $staticMethod = $staticMethod.Trim('\(\):')
        Write-Debug -Message "Calling static method '[$className]::$staticMethod(`$spec)'"
        $returnCode = "return [$className]::$staticMethod(`$args[0])"
    }
    else
    {
        # Class::New()
        $className = $Transformer
        Write-Debug -Message "Creating new [$className]"
        $returnCode = "return [$className]::new(`$args[0])"
    }

    $script = "$moduleString`r`n$returnCode"
    Write-Debug "ScriptBlock = {`r`n$script`r`n}"

    return [scriptblock]::Create($script).Invoke($ObjectToTransform)[0]
}
