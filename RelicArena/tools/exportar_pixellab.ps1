param(
    [Parameter(Mandatory=$true)][string]$CharacterKey,
    [Parameter(Mandatory=$true)][string]$CharacterId,
    [Parameter(Mandatory=$true)][string]$DownloadUrl
)
$ErrorActionPreference = 'Stop'
if ($CharacterKey -notmatch '^[a-z_]+$' -or $CharacterId -notmatch '^[0-9a-f-]{36}$') { throw 'Invalid asset identity' }
$expectedUrl = "https://api.pixellab.ai/mcp/characters/$CharacterId/download"
if ($DownloadUrl -ne $expectedUrl) { throw 'Use the official URL returned by get_character' }
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$exportRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot "assets/characters/$CharacterKey/realista_03"))
if (-not $exportRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Export outside project' }
New-Item -ItemType Directory -Path $exportRoot -Force | Out-Null
$archivePath = Join-Path $exportRoot 'pixellab_original.zip'
if (-not (Test-Path -LiteralPath $archivePath)) { Invoke-WebRequest -Uri $DownloadUrl -OutFile $archivePath }
$extractRoot = [IO.Path]::GetFullPath((Join-Path $exportRoot 'original'))
New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    foreach ($entry in $archive.Entries) {
        $destination = [IO.Path]::GetFullPath((Join-Path $extractRoot $entry.FullName))
        if (-not $destination.StartsWith($extractRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive path' }
    }
} finally { $archive.Dispose() }
Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force
$pngs = @(Get-ChildItem -LiteralPath $extractRoot -Filter '*.png' -Recurse -File)
$checksum = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
$receipt = [ordered]@{character_id=$CharacterId;character_key=$CharacterKey;download=$DownloadUrl;sha256=$checksum;png_count=$pngs.Count;originals_modified=$false}
$receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $exportRoot 'exportacao.json') -Encoding utf8
$receipt | ConvertTo-Json -Compress
