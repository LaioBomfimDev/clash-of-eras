param(
    [Parameter(Mandatory=$true)][string]$CharacterKey,
    [Parameter(Mandatory=$true)][string]$CharacterId
)
$ErrorActionPreference = 'Stop'
if ($CharacterKey -notmatch '^[a-z_]+$' -or $CharacterId -notmatch '^[0-9a-f-]{36}$') { throw 'Invalid asset identity' }
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$directions = [ordered]@{}
foreach ($direction in @('south','south-east','east','north-east','north','north-west','west','south-west')) {
    $relativePath = "assets/characters/$CharacterKey/realista_03/original/Idle/rotations/$direction.png"
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $relativePath))) { throw "Missing original $direction" }
    $directions[$direction] = 'res://' + $relativePath
}
$manifestPath = Join-Path $projectRoot 'assets/characters/manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$oldEntry = $manifest.characters.$CharacterKey
$newEntry = [ordered]@{character_id=$CharacterId;art_batch='realista_03';states=@{idle=@{directions=$directions}};original_animations=0}
if ($oldEntry -and $oldEntry.character_id -ne $CharacterId) { $newEntry.previous_character_id = $oldEntry.character_id }
if ($oldEntry -and $oldEntry.character_id -eq $CharacterId -and $oldEntry.previous_character_id) { $newEntry.previous_character_id = $oldEntry.previous_character_id }
$manifest.characters | Add-Member -NotePropertyName $CharacterKey -NotePropertyValue $newEntry -Force
$manifest.source = 'PixelLab original exports; realistic batch03 selected without modifying PNGs'
$manifest | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output "REGISTERED: $CharacterKey; 8 original rotations; no animation generated"
