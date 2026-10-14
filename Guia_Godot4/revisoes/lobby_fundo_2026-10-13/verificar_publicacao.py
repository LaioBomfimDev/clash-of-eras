"""Read-only comparison of published lobby runtime and repository references."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[3]
BASE = 'https://clash-of-eras.vercel.app/'
FILES = ['index.html', 'index.pck', 'lobby_video.js', 'media/lobby_loop.mp4', 'media/lobby_poster.webp', 'release.json']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def check_file(name):
    request = Request(BASE + name, headers={'Cache-Control': 'no-cache'})
    with urlopen(request, timeout=60) as response:
        data = response.read()
        result = {'file': name, 'bytes': len(data), 'sha256': digest(data),
                  'matches_local_dist': data == (ROOT / 'dist' / name).read_bytes(),
                  'content_type': response.headers.get('Content-Type')}
    if name == 'release.json':
        result['release'] = json.loads(data)
    return result


if __name__ == '__main__':
    with ThreadPoolExecutor(max_workers=4) as pool:
        files = list(pool.map(check_file, FILES))
    release = next(item['release'] for item in files if item['file'] == 'release.json')
    references = {}
    for key, name in [('simulation_sha256', 'RelicArena/simulation/arena_simulation.gd'),
                      ('server_sha256', 'RelicArena/net/online_server.gd')]:
        blob = subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=ROOT)
        references[key] = {'git_blob_sha256': digest(blob), 'release_sha256': release.get(key),
                           'matches_git_blob': digest(blob) == release.get(key)}
    report = {'checked_at_utc': datetime.now(timezone.utc).isoformat(), 'url': BASE,
              'observed_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'all_runtime_files_match_local_dist': all(item['matches_local_dist'] for item in files),
              'runtime': files, 'source_references_only': references}
    (Path(__file__).parent / 'public_integrity.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['all_runtime_files_match_local_dist'] else 1)
