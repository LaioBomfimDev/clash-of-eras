"""Verify all published Web files against the local export, streaming SHA-256."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import quote


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dist', type=Path, required=True)
    parser.add_argument('--url', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = args.dist.resolve(strict=True)
    report = {'url': args.url, 'checked_at_utc': datetime.now(timezone.utc).isoformat(), 'files': []}
    for local in sorted(root.rglob('*')):
        if not local.is_file():
            continue
        relative = local.relative_to(root).as_posix()
        url = args.url.rstrip('/') + '/' + ('' if relative == 'index.html' else quote(relative))
        row = {'file': relative}
        try:
            with local.open('rb') as stream:
                expected = hashlib.file_digest(stream, 'sha256').hexdigest()
            digest = hashlib.sha256()
            size = 0
            with urlopen(Request(url, headers={'Cache-Control': 'no-cache'}), timeout=90) as response:
                row['http_status'] = response.status
                row['content_type'] = response.headers.get('Content-Type')
                if relative == 'index.html':
                    row['cross_origin_opener_policy'] = response.headers.get('Cross-Origin-Opener-Policy')
                    row['cross_origin_embedder_policy'] = response.headers.get('Cross-Origin-Embedder-Policy')
                while chunk := response.read(1024 * 1024):
                    digest.update(chunk)
                    size += len(chunk)
            row.update(bytes=size, sha256=digest.hexdigest(), expected_sha256=expected,
                       matches_dist=digest.hexdigest() == expected)
        except Exception as error:
            row.update(matches_dist=False, error=str(error))
        report['files'].append(row)
        print(f"{'OK' if row['matches_dist'] else 'FAIL'} {relative}", flush=True)
    report['all_match'] = bool(report['files']) and all(row['matches_dist'] for row in report['files'])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    raise SystemExit(0 if report['all_match'] else 1)


if __name__ == '__main__':
    main()
