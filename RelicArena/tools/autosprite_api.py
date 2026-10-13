"""Cliente e utilitário para a REST API e geração de spritesheets do AutoSprite (autosprite.io).

Permite criar assets (props, moedas, itens, personagens), animá-los e exportar
spritesheets PNG com transparência diretamente para os diretórios de arte do Relic Arena.

Documentação oficial da API:
    https://www.autosprite.io/api
    https://www.autosprite.io/docs/api
    https://www.autosprite.io/docs/api-assets

Uso:
    python tools/autosprite_api.py --check
    python tools/autosprite_api.py --generate-coin
    python tools/autosprite_api.py --prompt "fantasy gold coin 32x32 pixel art" --out assets/ui/icons/
"""

import argparse
import json
import os
from pathlib import Path
import sys
import time
from typing import Any, Dict, Optional

try:
    import requests
except ImportError:
    requests = None


AUTOSPRITE_BASE_URL = "https://www.autosprite.io/api/v1"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT_DIR = PROJECT_ROOT / "assets" / "ui" / "icons"


def get_api_key() -> Optional[str]:
    """Obtém a chave AUTOSPRITE_API_KEY do ambiente ou do arquivo .env sem expô-la."""
    key = os.environ.get("AUTOSPRITE_API_KEY")
    if key and key.strip():
        return key.strip()

    # Tenta carregar do .env no diretório raiz do projeto ou home
    env_paths = [
        PROJECT_ROOT.parent / ".env",
        PROJECT_ROOT / ".env",
        Path.home() / ".env"
    ]
    for env_path in env_paths:
        if env_path.is_file():
            try:
                with open(env_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith("AUTOSPRITE_API_KEY="):
                            parts = line.split("=", 1)
                            if len(parts) == 2 and parts[1].strip():
                                return parts[1].strip().strip('"').strip("'")
            except Exception:
                pass
    return None


class AutoSpriteClient:
    """Cliente HTTP para a REST API do AutoSprite."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or get_api_key()
        self.base_url = AUTOSPRITE_BASE_URL
        self.session = requests.Session() if requests else None

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.session)

    def _headers(self) -> Dict[str, str]:
        return {
            "x-api-key": self.api_key or "",
            "Authorization": f"Bearer {self.api_key or ''}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def check_account(self) -> Dict[str, Any]:
        """Consulta o status da conta e saldo de créditos."""
        if not self.is_configured:
            return {"error": "Chave AUTOSPRITE_API_KEY não configurada no ambiente ou .env"}
        url = f"{self.base_url}/account"
        resp = self.session.get(url, headers=self._headers(), timeout=15)
        if resp.status_code == 200:
            return resp.json()
        return {"error": f"Erro {resp.status_code}: {resp.text}"}

    def create_asset(
        self,
        prompt: str,
        style: str = "pixel-art",
        size: str = "32x32",
        remove_background: bool = True
    ) -> Dict[str, Any]:
        """Cria um novo asset (prop/item) a partir de um prompt."""
        if not self.is_configured:
            return {"error": "Chave AUTOSPRITE_API_KEY não configurada"}
        url = f"{self.base_url}/assets"
        payload = {
            "prompt": prompt,
            "style": style,
            "size": size,
            "remove_background": remove_background,
        }
        resp = self.session.post(url, json=payload, headers=self._headers(), timeout=30)
        if resp.status_code in (200, 201, 202):
            return resp.json()
        return {"error": f"Falha ao criar asset: {resp.status_code} - {resp.text}"}

    def poll_asset(self, asset_id: str, timeout_sec: int = 120) -> Dict[str, Any]:
        """Aguarda a conclusão da geração do asset."""
        if not self.is_configured:
            return {"error": "Chave não configurada"}
        url = f"{self.base_url}/assets/{asset_id}"
        start = time.time()
        while time.time() - start < timeout_sec:
            resp = self.session.get(url, headers=self._headers(), timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                status = data.get("status")
                if status in ("completed", "ready", "done"):
                    return data
                elif status in ("failed", "error"):
                    return {"error": f"Geração do asset falhou: {data}"}
            time.sleep(3.0)
        return {"error": "Tempo limite excedido aguardando asset"}

    def animate_asset(self, asset_id: str, animation_type: str = "spin") -> Dict[str, Any]:
        """Solicita a animação do asset (ex: giro/rotação ou brilho)."""
        if not self.is_configured:
            return {"error": "Chave não configurada"}
        url = f"{self.base_url}/assets/{asset_id}/animate"
        payload = {
            "animation": animation_type,
            "type": animation_type,
            "frames": 8
        }
        resp = self.session.post(url, json=payload, headers=self._headers(), timeout=30)
        if resp.status_code in (200, 201, 202):
            return resp.json()
        return {"error": f"Falha ao animar asset: {resp.status_code} - {resp.text}"}

    def generate_spritesheet(self, asset_id: str) -> Dict[str, Any]:
        """Gera e exporta o spritesheet com atlas JSON."""
        if not self.is_configured:
            return {"error": "Chave não configurada"}
        url = f"{self.base_url}/assets/{asset_id}/spritesheets"
        resp = self.session.post(url, json={}, headers=self._headers(), timeout=30)
        if resp.status_code in (200, 201, 202):
            return resp.json()
        return {"error": f"Falha ao gerar spritesheet: {resp.status_code} - {resp.text}"}

    def download_spritesheet(self, download_url: str, dest_path: Path) -> bool:
        """Baixa o arquivo do spritesheet para o destino final."""
        if not self.session:
            return False
        resp = self.session.get(download_url, stream=True, timeout=30)
        if resp.status_code == 200:
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            with open(dest_path, "wb") as f:
                for chunk in resp.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description="AutoSprite CLI & API Integration")
    parser.add_argument("--check", action="store_true", help="Verifica a conexão com a API e créditos da conta")
    parser.add_argument("--generate-coin", action="store_true", help="Dispara a geração de nova moeda animada via AutoSprite")
    parser.add_argument("--prompt", type=str, help="Prompt personalizado para geração de asset")
    parser.add_argument("--out", type=str, default=str(DEFAULT_OUT_DIR), help="Diretório de saída para sprites")
    args = parser.parse_args()

    client = AutoSpriteClient()

    if args.check:
        if not client.is_configured:
            print("[AutoSprite] AUTOSPRITE_API_KEY não foi encontrada no ambiente ou .env.")
            print("[AutoSprite] Configure a chave para habilitar a geração em nuvem.")
            sys.exit(1)
        res = client.check_account()
        print(f"[AutoSprite] Status da conta: {json.dumps(res, indent=2)}")
        return

    if args.generate_coin:
        prompt = "Golden fantasy coin with embossed royal crown and lion crest, 32x32 pixel art, metallic bevel, specular shine, transparent background"
        print(f"[AutoSprite] Iniciando geração da moeda: '{prompt}'")
        if not client.is_configured:
            print("[AutoSprite] AVISO: AUTOSPRITE_API_KEY não encontrada.")
            print("[AutoSprite] Para gerar online via AutoSprite, cadastre sua chave no arquivo .env.")
            sys.exit(1)
        res = client.create_asset(prompt=prompt, style="pixel-art", size="32x32")
        print(f"[AutoSprite] Resposta: {res}")
        return

    if args.prompt:
        if not client.is_configured:
            print("[AutoSprite] AUTOSPRITE_API_KEY necessária para gerar com prompt.")
            sys.exit(1)
        res = client.create_asset(prompt=args.prompt)
        print(f"[AutoSprite] Asset criado: {res}")
        return

    print("Use --check ou --generate-coin. Execute com --help para ver opções.")


if __name__ == "__main__":
    main()
