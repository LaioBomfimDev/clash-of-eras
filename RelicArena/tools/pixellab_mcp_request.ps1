param(
    [Parameter(Mandatory=$true)][string]$ToolName,
    [string]$ArgumentsPath,
    [string]$OutputPath
)
$ErrorActionPreference = 'Stop'
# Read the credential already configured by the user; never print or persist it.
$configPath = Join-Path $env:USERPROFILE '.codex/config.toml'
$section = ''; $endpoint = $null; $authorization = $null
foreach ($line in [IO.File]::ReadAllLines($configPath)) {
    if ($line -match '^\[([^\]]+)\]') { $section = $Matches[1] }
    if ($section -eq 'mcp_servers.pixellabs' -and $line -match '^\s*url\s*=\s*"([^"]+)"') { $endpoint = $Matches[1] }
    if ($section -eq 'mcp_servers.pixellabs.http_headers' -and $line -match '^\s*Authorization\s*=\s*"([^"]+)"') { $authorization = $Matches[1] }
}
if ($endpoint -ne 'https://api.pixellab.ai/mcp' -or !$authorization) { throw 'Official PixelLab MCP configuration not found' }
$headers = @{ Authorization=$authorization; Accept='application/json, text/event-stream' }
function Send-McpRequest($payload) {
    $body = ConvertTo-Json -InputObject $payload -Depth 60 -Compress
    Invoke-WebRequest -UseBasicParsing -Uri $endpoint -Method Post -Headers $headers -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 120
}
try {
    $initial = Send-McpRequest @{jsonrpc='2.0';id=1;method='initialize';params=@{protocolVersion='2025-03-26';capabilities=@{};clientInfo=@{name='codex-project-pixellab';version='1.0'}}}
    if ($initial.Headers['Mcp-Session-Id']) { $headers['Mcp-Session-Id']=$initial.Headers['Mcp-Session-Id'] }
    $headers['MCP-Protocol-Version']='2025-03-26'
    Send-McpRequest @{jsonrpc='2.0';method='notifications/initialized'} | Out-Null
    $arguments = @{}
    if ($ArgumentsPath) { $arguments = Get-Content -LiteralPath $ArgumentsPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    $response = Send-McpRequest @{jsonrpc='2.0';id=2;method='tools/call';params=@{name=$ToolName;arguments=$arguments}}
    $content = [string]$response.Content
    if ($content.TrimStart().StartsWith('{')) { $message = $content | ConvertFrom-Json }
    else {
        $data = @($content -split "`n" | Where-Object { $_.StartsWith('data: ') } | ForEach-Object { $_.Substring(6).TrimEnd("`r") })
        if (!$data.Count) { throw 'No MCP response data' }
        $message = $data[-1] | ConvertFrom-Json
    }
    if ($message.error) { Write-Output ($message.error | ConvertTo-Json -Depth 20 -Compress); exit 1 }
    $result = $message.result
    if ($OutputPath) {
        $absoluteOutput = [IO.Path]::GetFullPath($OutputPath)
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($absoluteOutput)) | Out-Null
        [IO.File]::WriteAllText($absoluteOutput, ($result | ConvertTo-Json -Depth 60), [Text.UTF8Encoding]::new($false))
    }
    foreach ($block in $result.content) {
        if ($block.type -eq 'text') { Write-Output $block.text }
        elseif ($block.type -eq 'image') { Write-Output ('[image ' + $block.mimeType + ' saved in result JSON]') }
    }
    if ($result.isError) { exit 1 }
} catch {
    if ($_.Exception.Response) { Write-Output ('PixelLab HTTP status=' + [int]$_.Exception.Response.StatusCode) }
    else { Write-Output 'PixelLab request failed; credential not printed' }
    exit 1
}
