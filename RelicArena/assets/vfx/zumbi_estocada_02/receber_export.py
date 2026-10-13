"""Download and inspect official PixelLab exports; only these two isolated folders."""
from pathlib import Path, PurePosixPath
from urllib.request import urlopen
from urllib.error import HTTPError
from zipfile import ZipFile
from datetime import datetime, timezone
import base64, hashlib, json, re, sys
from PIL import Image

folder = Path(sys.argv[1]).resolve()
if folder.name not in {"zumbi_estocada_02", "zumbi_inspiracao_02"} or folder.parent.name != "vfx":
    raise ValueError("Unexpected destination")
response = folder / sys.argv[2]
result = json.loads(response.read_text(encoding="utf-8-sig"))
text = "\n".join(c["text"] for c in result["content"] if c["type"] == "text")
effect_id = re.search(r"effect id ([0-9a-f-]+)", text).group(1)
export_id = re.search(r"image id: ([0-9a-f-]+)", text).group(1)
base = re.search(r"download (https://api\.pixellab\.ai/mcp/pixel-tools/[0-9a-f-]+/):", text).group(1)
files = re.search(r"download https://[^\n]+/: ([^\n]+)", text).group(1).split(", ")
original = folder / "original"
unpacked = folder / "game_pack"
original.mkdir(exist_ok=True)
unpacked.mkdir(exist_ok=True)
downloaded = []
for name in files:
    if PurePosixPath(name).name != name or not name.endswith((".zip", ".png", ".gif", ".json")):
        raise ValueError("Unexpected download filename")
    with urlopen(base + name, timeout=60) as reply:
        status = reply.status
        data = reply.read()
    destination = original / name
    if destination.exists() and destination.read_bytes() != data:
        raise ValueError("Preserve existing original: bytes differ")
    if not destination.exists():
        destination.write_bytes(data)
    downloaded.append({"path": str(destination.relative_to(folder)).replace("\\", "/"), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "http_status": status})
zip_path = next(original.glob("*-game.zip"))
checks = []
with ZipFile(zip_path) as archive:
    if archive.testzip() is not None:
        raise ValueError("ZIP CRC failure")
    for member in archive.infolist():
        path = PurePosixPath(member.filename)
        if path.is_absolute() or ".." in path.parts or "\\" in member.filename or ":" in member.filename or (member.external_attr >> 16) & 0o170000 == 0o120000:
            raise ValueError("Unsafe ZIP member")
        destination = unpacked.joinpath(*path.parts).resolve()
        if not destination.is_relative_to(unpacked.resolve()):
            raise ValueError("ZIP member outside target")
        if member.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            continue
        data = archive.read(member)
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.read_bytes() != data:
            raise ValueError("Preserve extracted bytes: differ")
        if not destination.exists():
            destination.write_bytes(data)
        same = destination.read_bytes() == data
        if not same:
            raise ValueError("Extracted bytes differ")
        checks.append({"path": member.filename, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "byte_identical": same})
manifest = json.loads((unpacked / "manifest.json").read_text(encoding="utf-8"))
pngs = []
for path in [*original.glob("*.png"), *unpacked.glob("*.png")]:
    with Image.open(path) as im:
        im.load()
        pngs.append({"path": path.relative_to(folder).as_posix(), "mode": im.mode, "size": list(im.size)})
preview_source = folder / ("requests/09_lock_direction_result_image_1.png" if folder.name == "zumbi_estocada_02" else "requests/09_custom_pulse_result_image_1.png")
(folder / "preview.png").write_bytes(preview_source.read_bytes())
for i, content in enumerate(result["content"]):
    if content["type"] == "image":
        (folder / f"export_preview_{i}.png").write_bytes(base64.b64decode(content["data"]))
state = json.loads((folder / "estado.json").read_text(encoding="utf-8"))
receipt = {"date_utc": datetime.now(timezone.utc).isoformat(), "method": "PixelLab vfx_workbench deterministic FREE; no AI generation", "effect_id": effect_id, "step_id": state["step_id"], "export_image_id": export_id, "effect_url": "https://pixellab.ai/create-vfx?effect=" + effect_id, "export_base_url": base, "ai_generation_calls": 0, "paid_purchases": 0, "character_embedded": False, "runtime_integrated": False, "shared_manifest_modified": False, "gameplay_modified": False, "zip_bytes": zip_path.stat().st_size, "zip_sha256": hashlib.sha256(zip_path.read_bytes()).hexdigest(), "zip_crc_passed": True, "zip_paths_safe": True, "extracted_members": len(checks), "extracted_bytes": sum(c["bytes"] for c in checks), "extracted_byte_identical": True, "zip_member_checks": checks, "exported_downloads": downloaded, "pngs": pngs, "game_manifest": manifest, "visual_review": {"all_response_frames_reviewed": True, "native_and_enlarged_review": True, "final_user_approval": False, "gameplay_or_balance_tested": False}}
(folder / "exportacao.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2), encoding="utf-8")
state.update(state="exported_validated", effect_id=effect_id, export_image_id=export_id, effect_url=receipt["effect_url"], receipt="exportacao.json", zip_sha256=receipt["zip_sha256"])
(folder / "estado.json").write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"folder": folder.name, "effect_id": effect_id, "export_id": export_id, "zip_bytes": receipt["zip_bytes"], "zip_sha256": receipt["zip_sha256"], "files": len(checks), "pngs": pngs, "manifest": manifest}, ensure_ascii=True, indent=2))
