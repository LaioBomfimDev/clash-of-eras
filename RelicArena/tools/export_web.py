"""Export the Godot Web game and copy the browser lobby media alongside it."""
import argparse
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True, help='Output index.html path')
    args = parser.parse_args()
    project = args.project.resolve(strict=True)
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([args.godot, '--headless', '--path', str(project), '--export-release', 'Web', str(output)], check=True)
    shutil.copy2(project / 'client/lobby_video.js', output.parent / 'lobby_video.js')
    media = output.parent / 'media'
    media.mkdir(exist_ok=True)
    for name in ('lobby_loop.mp4', 'lobby_poster.webp'):
        shutil.copy2(project / 'client/web_media' / name, media / name)
    print('WEB_LOBBY_MEDIA_READY: external MP4 and poster copied; native OGV excluded from Web PCK.')


if __name__ == '__main__':
    main()
