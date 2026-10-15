import concurrent.futures
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen, Request

ROOT = Path(__file__).resolve().parent
records = json.loads((ROOT / 'ORIGEM.json').read_text(encoding='utf-8'))

def download(job):
    record, name = job
    target = ROOT / 'originais' / record['key'] / name
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        url = record['base_url'] + name
        with urlopen(Request(url, headers={'User-Agent': 'ClashOfErasAssetDownload/1.0'}), timeout=90) as response:
            data = response.read()
        target.write_bytes(data)
    return {'path': target.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'bytes': target.stat().st_size}

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(download, [(r, n) for r in records for n in r['files']]))
(ROOT / 'INTEGRIDADE.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
print(json.dumps({'downloaded_files': len(results), 'bytes': sum(r['bytes'] for r in results)}))
