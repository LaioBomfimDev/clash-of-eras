"""Read a standalone, unencrypted Godot PCK v3/v4 without changing game files.

Layout checked against the official Godot core/io/file_access_pack.cpp reader.
This is an audit helper, not a game export or publication command.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path


def inspect(path):
    blob = path.read_bytes()
    if blob[:4] != b"GDPC":
        raise ValueError("Expected a standalone Godot PCK")
    version, major, minor, patch, flags = struct.unpack_from("<5I", blob, 4)
    if version not in (3, 4) or flags & 1:
        raise ValueError("This audit supports unencrypted PCK v3/v4 only")
    file_base, directory = struct.unpack_from("<2Q", blob, 24)
    count, = struct.unpack_from("<I", blob, directory)
    cursor = directory + 4
    entries = []
    for _ in range(count):
        length, = struct.unpack_from("<I", blob, cursor)
        cursor += 4
        name = blob[cursor:cursor + length].decode("utf-8").rstrip("\0")
        cursor += length
        offset, size = struct.unpack_from("<2Q", blob, cursor)
        cursor += 16
        md5 = blob[cursor:cursor + 16].hex()
        cursor += 16
        entry_flags, = struct.unpack_from("<I", blob, cursor)
        cursor += 4
        start = file_base + offset
        if start + size > len(blob):
            raise ValueError("PCK entry outside file bounds: " + name)
        data = blob[start:start + size]
        entries.append({"path": name, "offset": start, "size": size,
                        "flags": entry_flags, "md5": md5,
                        "verified_md5": hashlib.md5(data).hexdigest() == md5,
                        "sha256": hashlib.sha256(data).hexdigest()})
    if not all(entry["verified_md5"] for entry in entries):
        raise ValueError("PCK entry MD5 validation failed")
    return {"pck_sha256": hashlib.sha256(blob).hexdigest(), "format": version,
            "engine": [major, minor, patch], "flags": flags,
            "file_base": file_base, "directory": directory, "count": count,
            "all_md5_valid": True, "entries": entries}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pck", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--compare", type=Path)
    args = parser.parse_args()
    report = inspect(args.pck)
    if args.compare:
        baseline = inspect(args.compare)
        old = {entry["path"]: entry for entry in baseline["entries"]}
        new = {entry["path"]: entry for entry in report["entries"]}
        report["comparison"] = {
            "baseline_sha256": baseline["pck_sha256"],
            "added": sorted(new.keys() - old.keys()),
            "removed": sorted(old.keys() - new.keys()),
            "changed": sorted(key for key in old.keys() & new.keys()
                              if old[key]["sha256"] != new[key]["sha256"]),
            "identical_count": sum(old[key]["sha256"] == new[key]["sha256"]
                                   for key in old.keys() & new.keys())}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items()
                      if key != "entries"}))


if __name__ == "__main__":
    main()
