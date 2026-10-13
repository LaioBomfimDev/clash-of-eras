"""Read-only verification of a PixelLab ZIP and its unchanged extracted PNGs."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("export_root", type=Path)
parser.add_argument("--rotations", type=Path)
parser.add_argument("--south-reference", type=Path)
args = parser.parse_args()
root = args.export_root.resolve()
archive_path = root / "pixellab_original.zip"
extracted = root / "original"
receipt = {"official_export": True, "sha256": hashlib.sha256(archive_path.read_bytes()).hexdigest(), "files": [], "mismatches": [], "rotations_pixel_equal": {}, "animation_frames": []}
with zipfile.ZipFile(archive_path) as archive:
    for entry in archive.infolist():
        if entry.is_dir():
            continue
        path = (extracted / entry.filename).resolve()
        if not path.is_relative_to(extracted.resolve()):
            raise ValueError("Unsafe archive path")
        data = archive.read(entry)
        sha = hashlib.sha256(data).hexdigest()
        equal = path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() == sha
        receipt["files"].append({"path": entry.filename, "sha256": sha, "bytes": len(data), "unchanged": equal})
        if not equal:
            receipt["mismatches"].append(entry.filename)
        if path.suffix.lower() != ".png":
            continue
        with Image.open(path) as opened:
            image = opened.convert("RGBA")
            if "/animations/" in entry.filename:
                receipt["animation_frames"].append({"path": entry.filename, "size": list(image.size), "alpha_bbox": image.getchannel("A").getbbox()})
            elif args.rotations and "/rotations/" in entry.filename:
                original = args.south_reference if path.stem == "south" and args.south_reference else args.rotations / path.name
                with Image.open(original) as source:
                    source_rgba = source.convert("RGBA")
                    receipt["rotations_pixel_equal"][path.stem] = source_rgba.size == image.size and source_rgba.tobytes() == image.tobytes()
(root / "exportacao.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"files": len(receipt["files"]), "mismatches": len(receipt["mismatches"]), "animation_frames": len(receipt["animation_frames"]), "rotations_equal": sum(receipt["rotations_pixel_equal"].values()), "rotations_checked": len(receipt["rotations_pixel_equal"]), "sha256": receipt["sha256"]}))
raise SystemExit(1 if receipt["mismatches"] or not all(receipt["rotations_pixel_equal"].values()) else 0)
