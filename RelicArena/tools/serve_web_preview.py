"""Serve an exported Godot Web build on localhost with its required isolation headers.
Usage: python serve_web_preview.py PATH_TO_BUILD [PORT]
"""
import functools
import http.server
import pathlib
import sys


class PreviewHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    directory = pathlib.Path(sys.argv[1]).resolve(strict=True)
    if not directory.is_dir():
        raise SystemExit("Build path must be a directory")
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8766
    handler = functools.partial(PreviewHandler, directory=str(directory))
    with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as server:
        print(f"Godot Web preview: http://127.0.0.1:{port}/", flush=True)
        server.serve_forever()
