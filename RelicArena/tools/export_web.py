"""Export the Godot Web game and copy the browser lobby media alongside it."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def sha256(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def source_manifest(project):
    files = [project / name for name in ('project.godot', 'main.tscn', 'export_presets.cfg')]
    for directory in ('client', 'data', 'simulation', 'net', 'server', 'assets'):
        files.extend(path for path in (project / directory).rglob('*')
                     if path.is_file() and '__pycache__' not in path.parts
                     and path.suffix != '.tmp')
    return {path.relative_to(project).as_posix(): sha256(path) for path in sorted(files)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True, help='Output index.html path')
    parser.add_argument('--build-id', help='Release identifier; defaults to UTC export time')
    args = parser.parse_args()
    project = args.project.resolve(strict=True)
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    sources_before = source_manifest(project)
    git_head = subprocess.run(['git', '-C', str(project), 'rev-parse', 'HEAD'],
                              check=True, capture_output=True, text=True).stdout.strip()
    subprocess.run([args.godot, '--headless', '--path', str(project), '--export-release', 'Web', str(output)], check=True)
    shutil.copy2(project / 'client/lobby_video.js', output.parent / 'lobby_video.js')
    media = output.parent / 'media'
    media.mkdir(exist_ok=True)
    for name in ('lobby_loop.mp4', 'lobby_poster.webp'):
        shutil.copy2(project / 'client/web_media' / name, media / name)
    sources_after = source_manifest(project)
    if sources_before != sources_after:
        changed = sorted(name for name in sources_before.keys() | sources_after.keys()
                         if sources_before.get(name) != sources_after.get(name))
        raise RuntimeError('Source changed during export; do not publish this build: ' + ', '.join(changed[:20]))
    manifest_path = output.parent / 'source_manifest.json'
    manifest_path.write_text(json.dumps(sources_after, indent=2) + '\n', encoding='utf-8')
    source_files = ['client/main.gd', 'client/prototype_audio.gd', 'assets/vfx/manifest.json',
                    'data/debug_characters.json', 'simulation/arena_simulation.gd',
                    'simulation/match_session.gd', 'server/dedicated_server.gd',
                    'net/online_server.gd', 'net/perspective_mapper.gd']
    release = {
        'build_id': args.build_id or datetime.now(timezone.utc).strftime('web-%Y%m%dT%H%M%SZ'),
        'source': 'exported-workspace; source hashes recorded at export',
        'source_git_head_at_export': git_head,
        'source_manifest_sha256': sha256(manifest_path),
        'source_file_count': len(sources_after),
        'pck_sha256': sha256(output.with_suffix('.pck')),
        'html_sha256': sha256(output),
        'wasm_sha256': sha256(output.with_suffix('.wasm')),
        'javascript_sha256': sha256(output.with_suffix('.js')),
        'simulation_sha256': sha256(project / 'simulation/arena_simulation.gd'),
        'server_sha256': sha256(project / 'net/online_server.gd'),
        'dedicated_entrypoint_sha256': sha256(project / 'server/dedicated_server.gd'),
        'source_sha256': {name: sha256(project / name) for name in source_files},
        'external_media_sha256': {name: sha256(output.parent / name) for name in
                                 ['lobby_video.js', 'media/lobby_loop.mp4', 'media/lobby_poster.webp']},
    }
    (output.parent / 'release.json').write_text(json.dumps(release, indent=2) + '\n', encoding='utf-8')
    print('WEB_LOBBY_MEDIA_READY: external MP4 and poster copied; native OGV excluded from Web PCK.')


if __name__ == '__main__':
    main()
