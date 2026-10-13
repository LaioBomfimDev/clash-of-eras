import os
import json
import urllib.request

config_path = os.path.expanduser('~/.codex/config.toml')
endpoint = None
auth = None
if os.path.exists(config_path):
    with open(config_path, 'r', encoding='utf-8') as f:
        section = ''
        for line in f:
            line = line.strip()
            if line.startswith('[') and line.endswith(']'):
                section = line[1:-1]
            if section == 'mcp_servers.pixellabs' and line.startswith('url'):
                endpoint = line.split('=', 1)[1].strip().strip('"').strip("'")
            if section == 'mcp_servers.pixellabs.http_headers' and line.startswith('Authorization'):
                auth = line.split('=', 1)[1].strip().strip('"').strip("'")

if endpoint and auth:
    headers = {
        'Authorization': auth,
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream'
    }
    req1 = urllib.request.Request(
        endpoint,
        data=json.dumps({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'initialize',
            'params': {
                'protocolVersion': '2025-03-26',
                'capabilities': {},
                'clientInfo': {'name': 'test', 'version': '1.0'}
            }
        }).encode('utf-8'),
        headers=headers
    )
    with urllib.request.urlopen(req1) as resp1:
        sess_id = resp1.headers.get('Mcp-Session-Id')
        if sess_id:
            headers['Mcp-Session-Id'] = sess_id
        headers['MCP-Protocol-Version'] = '2025-03-26'
        
    req2 = urllib.request.Request(
        endpoint,
        data=json.dumps({
            'jsonrpc': '2.0',
            'id': 2,
            'method': 'tools/list',
            'params': {}
        }).encode('utf-8'),
        headers=headers
    )
    with urllib.request.urlopen(req2) as resp2:
        raw = resp2.read().decode('utf-8')
        lines = [line[6:] for line in raw.split('\n') if line.startswith('data: ')]
        if lines:
            data = json.loads(lines[-1])
        else:
            data = json.loads(raw)
    for t in data.get('result', {}).get('tools', []):
        if t['name'] in ['create_ui_asset', 'vfx_workbench', 'create_object_pro_flash']:
            print('=== TOOL:', t['name'], '===')
            print(json.dumps(t.get('inputSchema'), indent=2))

