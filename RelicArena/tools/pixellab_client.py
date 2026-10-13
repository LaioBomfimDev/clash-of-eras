import os
import json
import urllib.request
from typing import Any, Dict, Optional

class PixelLabClient:
    def __init__(self):
        config_path = os.path.expanduser('~/.codex/config.toml')
        self.endpoint = None
        self.auth = None
        if os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                section = ''
                for line in f:
                    line = line.strip()
                    if line.startswith('[') and line.endswith(']'):
                        section = line[1:-1]
                    if section == 'mcp_servers.pixellabs' and line.startswith('url'):
                        self.endpoint = line.split('=', 1)[1].strip().strip('"').strip("'")
                    if section == 'mcp_servers.pixellabs.http_headers' and line.startswith('Authorization'):
                        self.auth = line.split('=', 1)[1].strip().strip('"').strip("'")
        if not self.endpoint or not self.auth:
            raise RuntimeError("Configuração do PixelLab MCP não encontrada em ~/.codex/config.toml")
        
        self.headers = {
            'Authorization': self.auth,
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/event-stream'
        }
        self._init_session()

    def _init_session(self):
        req = urllib.request.Request(
            self.endpoint,
            data=json.dumps({
                'jsonrpc': '2.0',
                'id': 1,
                'method': 'initialize',
                'params': {
                    'protocolVersion': '2025-03-26',
                    'capabilities': {},
                    'clientInfo': {'name': 'relic_arena_agent', 'version': '1.0'}
                }
            }).encode('utf-8'),
            headers=self.headers
        )
        with urllib.request.urlopen(req) as resp:
            sess_id = resp.headers.get('Mcp-Session-Id')
            if sess_id:
                self.headers['Mcp-Session-Id'] = sess_id
            self.headers['MCP-Protocol-Version'] = '2025-03-26'

    def call_tool(self, name: str, arguments: Dict[str, Any] = {}) -> Any:
        req = urllib.request.Request(
            self.endpoint,
            data=json.dumps({
                'jsonrpc': '2.0',
                'id': 2,
                'method': 'tools/call',
                'params': {'name': name, 'arguments': arguments}
            }).encode('utf-8'),
            headers=self.headers
        )
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode('utf-8')
            lines = [line[6:] for line in raw.split('\n') if line.startswith('data: ')]
            data = json.loads(lines[-1]) if lines else json.loads(raw)
            if 'error' in data:
                raise RuntimeError(f"Erro PixelLab: {data['error']}")
            return data.get('result', {})

if __name__ == '__main__':
    client = PixelLabClient()
    res = client.call_tool('get_balance')
    print("Balance result:", json.dumps(res, indent=2))
