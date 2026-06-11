import yaml, os
from pathlib import Path
import pytest

ROOT = Path(__file__).resolve().parent.parent
MAPPING = ROOT / "sprites" / "mapping.yaml"
SPRITES_DIR = ROOT / "web" / "static" / "img" / "sprites"


def _load_mapping():
    with open(MAPPING) as f:
        return yaml.safe_load(f)


def _all_sprite_ids():
    m = _load_mapping()
    ids = []
    for group in ["heroes", "deities"]:
        if group in m:
            for key, val in m[group].items():
                ids.append((key, val["sprite"]))
    return ids


def test_mapping_has_enough_entries():
    m = _load_mapping()
    total = len(m.get("heroes", {})) + len(m.get("deities", {}))
    assert total >= 15, f"Expected >= 15 sprites, got {total}"


def test_all_sprite_files_exist():
    for sid, filename in _all_sprite_ids():
        path = SPRITES_DIR / filename
        assert path.exists(), f"Sprite file missing: {path} (for agent {sid})"


def test_all_sprites_valid_png_96x32():
    import struct
    for sid, filename in _all_sprite_ids():
        path = SPRITES_DIR / filename
        with open(path, 'rb') as f:
            sig = f.read(8)
            assert sig == b'\x89PNG\r\n\x1a\n', f"{path} is not a PNG"
            # Read IHDR chunk
            f.read(4)   # length
            f.read(4)   # IHDR
            w, h = struct.unpack('>II', f.read(8))
            assert w == 96, f"{path} width is {w}, expected 96"
            assert h == 32, f"{path} height is {h}, expected 32"
