function ConvertTo-TitleCase {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        $Text
    )

    begin {
        $TextInfo = (Get-Culture).TextInfo
    }

    process {
        $Text | Foreach-Object {
            $TextInfo.ToTitleCase($_)
        }
    }
}