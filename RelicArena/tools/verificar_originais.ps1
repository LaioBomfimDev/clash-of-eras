$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$exports = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/characters') -Filter 'exportacao.json' -File -Recurse)
$archivesChecked = 0
$filesChecked = 0
$pngsChecked = 0
foreach ($receiptFile in $exports) {
    $receipt = Get-Content -LiteralPath $receiptFile.FullName -Raw | ConvertFrom-Json
    $archivePath = Join-Path $receiptFile.DirectoryName 'pixellab_original.zip'
    if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $receipt.sha256) { throw "Changed archive: $archivePath" }
    $extractRoot = [IO.Path]::GetFullPath((Join-Path $receiptFile.DirectoryName 'original'))
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($entry in $archive.Entries) {
            if ([string]::IsNullOrEmpty($entry.Name)) { continue }
            $path = [IO.Path]::GetFullPath((Join-Path $extractRoot $entry.FullName))
            if (-not $path.StartsWith($extractRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive path' }
            $stream = $entry.Open()
            $hasher = [Security.Cryptography.SHA256]::Create()
            try { $originalHash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-','') }
            finally { $stream.Dispose(); $hasher.Dispose() }
            if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $originalHash) { throw "Changed original: $path" }
            $filesChecked++
            if ($entry.Name.EndsWith('.png')) { $pngsChecked++ }
        }
    } finally { $archive.Dispose() }
    $archivesChecked++
}
$result = [ordered]@{archives_checked=$archivesChecked;original_files_checked=$filesChecked;pngs_checked=$pngsChecked;changed_files=0;success=$true}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'captures/integridade_lote_03.json') -Encoding utf8
$result | ConvertTo-Json -Compress
