from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import struct
import tkinter as tk


@dataclass
class SpriteFrame:
    width: int
    height: int
    pixels: bytes


def _unswizzle_chain4_columns(pixels: bytes, width: int, height: int) -> bytes:
    """
    Convert plane-grouped Chain-4 ordering to linear left->right pixels.

    Stored order (source):
      first all pixels where x%4==0 (for all rows),
      then all pixels where x%4==1 (for all rows),
      then x%4==2, then x%4==3.
    Target row order:
      x = 0,1,2,3,4,5,...
    """
    if width <= 1 or height <= 0:
        return pixels
    expected = width * height
    if len(pixels) != expected:
        return pixels

    out = bytearray(expected)
    src_i = 0
    for phase in range(4):
        for y in range(height):
            row_base = y * width
            x = phase
            while x < width:
                out[row_base + x] = pixels[src_i]
                src_i += 1
                x += 4
    return bytes(out)


def load_palette(path: Path) -> List[Tuple[int, int, int]]:
    data = path.read_bytes()
    if len(data) < 768:
        raise ValueError(f"Palette zu kurz: {path}")
    out: List[Tuple[int, int, int]] = []
    for i in range(0, 768, 3):
        r = min(255, data[i] * 4)
        g = min(255, data[i + 1] * 4)
        b = min(255, data[i + 2] * 4)
        out.append((r, g, b))
    return out


def load_asset_palette(
    distribution_dir: Path, sprite_file: Optional[Path] = None
) -> Optional[List[Tuple[int, int, int]]]:
    if sprite_file is not None and sprite_file.exists():
        data = sprite_file.read_bytes()
        if len(data) >= 768:
            return load_palette_from_bytes(data[:768])

    drake_spr = distribution_dir / "drake.spr"
    if drake_spr.exists():
        data = drake_spr.read_bytes()
        if len(data) >= 768:
            return load_palette_from_bytes(data[:768])
    palette_path = distribution_dir / "palette.dat"
    if palette_path.exists():
        return load_palette(palette_path)
    return None


def parse_tp_sprite_frames(data: bytes) -> List[SpriteFrame]:
    if len(data) < 4:
        return []
    w, h = struct.unpack_from("<HH", data, 0)
    if w == 0 or h == 0:
        return []
    frame_size = 4 + (w * h)
    if frame_size <= 4:
        return []
    if len(data) % frame_size != 0:
        # Not this format
        return []
    frames: List[SpriteFrame] = []
    for pos in range(0, len(data), frame_size):
        fw, fh = struct.unpack_from("<HH", data, pos)
        if fw != w or fh != h:
            return []
        raw_pixels = data[pos + 4 : pos + frame_size]
        pixels = _unswizzle_chain4_columns(raw_pixels, fw, fh)
        frames.append(SpriteFrame(width=fw, height=fh, pixels=pixels))
    return frames


def parse_first_tp_frame_from_block(data: bytes) -> Optional[SpriteFrame]:
    if len(data) < 4:
        return None
    w, h = struct.unpack_from("<HH", data, 0)
    if w <= 0 or h <= 0:
        return None
    need = 4 + (w * h)
    if need > len(data):
        return None
    raw_pixels = data[4:need]
    pixels = _unswizzle_chain4_columns(raw_pixels, w, h)
    return SpriteFrame(width=w, height=h, pixels=pixels)


def frame_to_photoimage(
    root: tk.Misc,
    frame: SpriteFrame,
    palette: List[Tuple[int, int, int]],
    transparent_index: Optional[int] = 0,
    scale_x: int = 1,
    scale_y: int = 1,
) -> tk.PhotoImage:
    img = tk.PhotoImage(master=root, width=frame.width, height=frame.height)
    rows: List[str] = []
    for y in range(frame.height):
        cols: List[str] = []
        base = y * frame.width
        for x in range(frame.width):
            idx = frame.pixels[base + x]
            if transparent_index is not None and idx == transparent_index:
                cols.append("#000001")
            else:
                r, g, b = palette[idx]
                cols.append(f"#{r:02x}{g:02x}{b:02x}")
        rows.append("{" + " ".join(cols) + "}")
    img.put(" ".join(rows), to=(0, 0, frame.width, frame.height))
    if transparent_index is not None:
        for y in range(frame.height):
            base = y * frame.width
            for x in range(frame.width):
                if frame.pixels[base + x] == transparent_index:
                    img.transparency_set(x, y, True)
    if scale_x > 1 or scale_y > 1:
        img = img.zoom(scale_x, scale_y)
    return img


def load_sprite_bank(
    root: tk.Misc,
    distribution_dir: Path,
    scale: int = 1,
    sprite_file: Optional[Path] = None,
) -> Dict[int, tk.PhotoImage]:
    """
    Returns sprite-index -> Tk PhotoImage (index same as Pascal Sprites[] array, 0-based).
    Tries to load spr1.dat..spr26.dat if present.
    """
    # If a sprite file is explicitly given, use only that.
    if sprite_file is not None:
        return _load_sprite_bank_from_file(root, sprite_file, scale=scale)

    # Fallback: unpacked spr*.dat files.
    palette = load_asset_palette(distribution_dir)
    if palette is None:
        return {}
    loaded: Dict[int, tk.PhotoImage] = {}
    for idx in range(26):
        path = distribution_dir / f"spr{idx + 1}.dat"
        if not path.exists():
            continue
        frames = parse_tp_sprite_frames(path.read_bytes())
        if not frames:
            continue
        frame = frames[0]
        sx = scale
        sy = scale
        img = frame_to_photoimage(root, frame, palette, scale_x=sx, scale_y=sy)
        loaded[idx] = img
    return loaded


def load_background_bank(
    root: tk.Misc,
    distribution_dir: Path,
    scale: int = 1,
    sprite_file: Optional[Path] = None,
) -> Dict[str, tk.PhotoImage]:
    """
    Load .bld assets that are simple raw images:
    [u16 width][u16 height][width*height palette indices]
    """
    palette = load_asset_palette(distribution_dir, sprite_file=sprite_file)
    if palette is None:
        return {}

    out: Dict[str, tk.PhotoImage] = {}
    for path in sorted(distribution_dir.glob("*.bld")):
        frame = _parse_raw_bld(path)
        if frame is None:
            continue
        img = frame_to_photoimage(
            root,
            frame,
            palette,
            transparent_index=None,
            scale_x=scale,
            scale_y=scale,
        )
        out[path.stem.lower()] = img
    return out


def _load_sprite_bank_from_file(
    root: tk.Misc, sprite_file: Path, scale: int = 1
) -> Dict[int, tk.PhotoImage]:
    if not sprite_file.exists():
        return {}

    data = sprite_file.read_bytes()
    # Layout from drakepas/drakespr.pas:
    # pal(768), status(4500), hero4*810, spider80*472, exp13*579,
    # skorp 4*10*342, fleder13*184, mauer12*900, level sprites 26*800
    needed = 768 + 4500 + (4 * 810) + (80 * 472) + (13 * 579) + (40 * 342) + (13 * 184) + (12 * 900) + (26 * 800)
    if len(data) < needed:
        return {}
    if len(data) != needed:
        # Unknown variant; avoid unsafe guessing.
        return {}

    palette = load_palette_from_bytes(data[:768])
    offset = 768 + 4500 + (4 * 810) + (80 * 472) + (13 * 579) + (40 * 342) + (13 * 184) + (12 * 900)
    loaded: Dict[int, tk.PhotoImage] = {}
    for idx in range(26):
        block = data[offset : offset + 800]
        offset += 800
        frame = parse_first_tp_frame_from_block(block)
        if frame is None:
            continue
        loaded[idx] = frame_to_photoimage(root, frame, palette, scale_x=scale, scale_y=scale)
    return loaded


def load_palette_from_bytes(data: bytes) -> List[Tuple[int, int, int]]:
    if len(data) < 768:
        raise ValueError("Palette-Bytes zu kurz")
    out: List[Tuple[int, int, int]] = []
    for i in range(0, 768, 3):
        r = min(255, data[i] * 4)
        g = min(255, data[i + 1] * 4)
        b = min(255, data[i + 2] * 4)
        out.append((r, g, b))
    return out


def _parse_raw_bld(path: Path) -> Optional[SpriteFrame]:
    data = path.read_bytes()
    if len(data) < 4:
        return None
    w, h = struct.unpack_from("<HH", data, 0)
    if w <= 0 or h <= 0:
        return None
    need = 4 + (w * h)
    if need != len(data):
        # Many .bld files use other formats; skip those here.
        return None
    raw = data[4:need]
    unsw = _unswizzle_chain4_columns(raw, w, h)
    # Auto-pick the mapping with smoother adjacency (works well for
    # wald1/wald2_2 and keeps compatibility for simpler files).
    pixels = unsw if _adjacency_score(unsw, w, h) < _adjacency_score(raw, w, h) else raw
    return SpriteFrame(width=w, height=h, pixels=pixels)


def _adjacency_score(pixels: bytes, width: int, height: int) -> float:
    if width <= 1 or height <= 0:
        return 0.0
    total = 0
    count = 0
    for y in range(height):
        row = pixels[y * width : (y + 1) * width]
        for x in range(width - 1):
            total += abs(row[x + 1] - row[x])
            count += 1
    return total / count if count else 0.0
