# Encoding should be UTF8 with BOM to support emojicons.

$wikiUri = "https://en.wikipedia.org/api/rest_v1/page/random/summary"

function Write-HostCenter {
    param($Message)
    Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message)
}
Write-Host "`n`n"
Write-HostCenter "----------------------------"
Write-HostCenter "👨‍🎤 Random Album Cover Generator 👩‍🎤"
Write-HostCenter "----------------------------"
Write-Host "`n`n"


$wikiRes = Invoke-RestMethod -uri $wikiUri
$bandName = $wikiRes.Title
$bandName