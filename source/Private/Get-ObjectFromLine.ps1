function Get-ObjectFromLine {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding()]
    [OutputType([Object])]
    param (
        [Object]
        $Line,

        [ObjectMatch]
        $Definition
    )

    ,$Definition.GetObject($Line)

}
