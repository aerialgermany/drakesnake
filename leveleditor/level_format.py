from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import struct
from typing import List, Tuple


LEVEL_WIDTH = 20
LEVEL_HEIGHT = 28
GRID_SIZE = LEVEL_WIDTH * LEVEL_HEIGHT


class LevelFormatError(ValueError):
    pass


@dataclass
class Coord:
    x: int
    y: int


@dataclass
class SubLevel:
    grid: List[int] = field(default_factory=lambda: [0] * GRID_SIZE)
    spin: List[Coord] = field(default_factory=list)
    fleder: List[Coord] = field(default_factory=list)
    flaschen: List[Coord] = field(default_factory=list)
    mauer: List[Coord] = field(default_factory=list)
    skorpion: List[Coord] = field(default_factory=list)
    gbusch: List[Coord] = field(default_factory=list)
    kbusch: List[Coord] = field(default_factory=list)
    has_background: bool = False
    background_x: int = 0
    background_y: int = 0
    background_name: str = ""

    def validate(self) -> None:
        if len(self.grid) != GRID_SIZE:
            raise LevelFormatError(f"Grid has {len(self.grid)} entries, expected {GRID_SIZE}.")
        for value in self.grid:
            if not 0 <= value <= 255:
                raise LevelFormatError(f"Invalid tile ID: {value}")
        self._validate_coord_list("spin", self.spin, 10)
        self._validate_coord_list("fleder", self.fleder, 10)
        self._validate_coord_list("flaschen", self.flaschen, 10)
        self._validate_coord_list("mauer", self.mauer, 10)
        self._validate_coord_list("skorpion", self.skorpion, 10)
        self._validate_coord_list("gbusch", self.gbusch, 20)
        self._validate_coord_list("kbusch", self.kbusch, 20)
        if self.has_background:
            _validate_u16(self.background_x, "background_x")
            _validate_u16(self.background_y, "background_y")
            _validate_pascal8(self.background_name, "background_name")

    @staticmethod
    def _validate_coord_list(name: str, coords: List[Coord], max_size: int) -> None:
        if len(coords) > max_size:
            raise LevelFormatError(f"{name} has {len(coords)} entries, max allowed is {max_size}.")
        for coord in coords:
            _validate_u16(coord.x, f"{name}.x")
            _validate_u16(coord.y, f"{name}.y")

    def to_bytes(self) -> bytes:
        self.validate()
        out = bytearray(self.grid)
        _append_coord_list(out, self.spin)
        _append_coord_list(out, self.fleder)
        _append_coord_list(out, self.flaschen)
        _append_coord_list(out, self.mauer)
        _append_coord_list(out, self.skorpion)
        _append_coord_list(out, self.gbusch)
        _append_coord_list(out, self.kbusch)
        out.append(1 if self.has_background else 0)
        if self.has_background:
            out.extend(struct.pack("<HH", self.background_x, self.background_y))
            out.extend(_encode_pascal8(self.background_name))
        return bytes(out)

    @classmethod
    def from_bytes(cls, data: bytes) -> "SubLevel":
        if len(data) < GRID_SIZE:
            raise LevelFormatError("Sublevel is shorter than grid data.")
        i = 0
        grid = list(data[i : i + GRID_SIZE])
        i += GRID_SIZE

        spin, i = _read_coord_list(data, i, 10, "spin")
        fleder, i = _read_coord_list(data, i, 10, "fleder")
        flaschen, i = _read_coord_list(data, i, 10, "flaschen")
        mauer, i = _read_coord_list(data, i, 10, "mauer")
        skorpion, i = _read_coord_list(data, i, 10, "skorpion")
        gbusch, i = _read_coord_list(data, i, 20, "gbusch")
        kbusch, i = _read_coord_list(data, i, 20, "kbusch")

        if i >= len(data):
            raise LevelFormatError("Sublevel ends before background flag.")
        has_background = data[i] > 0
        i += 1

        background_x = 0
        background_y = 0
        background_name = ""
        if has_background:
            if i + 13 > len(data):
                raise LevelFormatError("Sublevel ends inside background data.")
            background_x, background_y = struct.unpack_from("<HH", data, i)
            i += 4
            background_name = _decode_pascal8(data[i : i + 9])
            i += 9

        if i != len(data):
            raise LevelFormatError(
                f"Sublevel has {len(data) - i} unexplained trailing bytes (format mismatch)."
            )

        return cls(
            grid=grid,
            spin=spin,
            fleder=fleder,
            flaschen=flaschen,
            mauer=mauer,
            skorpion=skorpion,
            gbusch=gbusch,
            kbusch=kbusch,
            has_background=has_background,
            background_x=background_x,
            background_y=background_y,
            background_name=background_name,
        )


@dataclass
class PackedLevel:
    hero_x: int = 0
    hero_y: int = 0
    # 0 means no connection / "fin"
    connections: List[Tuple[int, int, int, int]] = field(default_factory=list)
    sublevels: List[SubLevel] = field(default_factory=list)

    def validate(self) -> None:
        if not self.sublevels:
            raise LevelFormatError("At least one sublevel is required.")
        n = len(self.sublevels)
        if n > 25:
            raise LevelFormatError("At most 25 sublevels are allowed.")
        _validate_u16(self.hero_x, "hero_x")
        _validate_u16(self.hero_y, "hero_y")
        if len(self.connections) != n:
            raise LevelFormatError("Connection count does not match sublevel count.")
        for idx, conn in enumerate(self.connections, start=1):
            if len(conn) != 4:
                raise LevelFormatError(f"Sublevel {idx}: connection must have 4 values.")
            for value in conn:
                if not 0 <= value <= n:
                    raise LevelFormatError(
                        f"Sublevel {idx}: connection value {value} outside 0..{n}."
                    )
        for sub in self.sublevels:
            sub.validate()

    def to_bytes(self) -> bytes:
        self.validate()
        n = len(self.sublevels)
        chunks = [sub.to_bytes() for sub in self.sublevels]
        offsets: List[int] = []
        pos = 5 + n * 8
        for chunk in chunks:
            offsets.append(pos)
            pos += len(chunk)

        out = bytearray()
        out.append(n)
        out.extend(struct.pack("<HH", self.hero_x, self.hero_y))
        for conn in self.connections:
            out.extend(struct.pack("<BBBB", *conn))
        for off in offsets:
            out.extend(struct.pack("<I", off))
        for chunk in chunks:
            out.extend(chunk)
        return bytes(out)

    @classmethod
    def from_bytes(cls, data: bytes) -> "PackedLevel":
        if len(data) < 5:
            raise LevelFormatError("File is too short.")
        n = data[0]
        if n == 0:
            raise LevelFormatError("File contains 0 sublevels.")
        if n > 25:
            raise LevelFormatError(f"File contains {n} sublevels; max is 25.")

        header_size = 5 + n * 8
        if len(data) < header_size:
            raise LevelFormatError("File is shorter than header.")

        hero_x, hero_y = struct.unpack_from("<HH", data, 1)

        con_raw = struct.unpack_from("<" + ("B" * (n * 4)), data, 5)
        connections = [
            (con_raw[i * 4], con_raw[i * 4 + 1], con_raw[i * 4 + 2], con_raw[i * 4 + 3])
            for i in range(n)
        ]
        offsets = list(struct.unpack_from("<" + ("I" * n), data, 5 + n * 4))
        if offsets != sorted(offsets):
            raise LevelFormatError("Sublevel offsets are not ascending.")
        if offsets[0] < header_size:
            raise LevelFormatError("First sublevel offset points into header.")
        if offsets[-1] >= len(data):
            raise LevelFormatError("Last sublevel offset points outside the file.")

        sublevels: List[SubLevel] = []
        for i in range(n):
            start = offsets[i]
            end = offsets[i + 1] if i + 1 < n else len(data)
            if end <= start:
                raise LevelFormatError("Empty or negative sublevel range.")
            chunk = data[start:end]
            sublevels.append(SubLevel.from_bytes(chunk))

        level = cls(hero_x=hero_x, hero_y=hero_y, connections=connections, sublevels=sublevels)
        level.validate()
        return level

    @classmethod
    def new_empty(cls, count: int = 1) -> "PackedLevel":
        if count < 1 or count > 25:
            raise LevelFormatError("Sublevel count must be between 1 and 25.")
        subs = [SubLevel() for _ in range(count)]
        con = [(0, 0, 0, 0) for _ in range(count)]
        return cls(hero_x=0, hero_y=0, connections=con, sublevels=subs)


def load_packed_level(path: str | Path) -> PackedLevel:
    data = Path(path).read_bytes()
    return PackedLevel.from_bytes(data)


def save_packed_level(path: str | Path, level: PackedLevel) -> None:
    Path(path).write_bytes(level.to_bytes())


def _validate_u16(value: int, field_name: str) -> None:
    if not 0 <= int(value) <= 0xFFFF:
        raise LevelFormatError(f"{field_name} must be 0..65535, got {value}.")


def _validate_pascal8(value: str, field_name: str) -> None:
    encoded = value.encode("ascii", errors="ignore")
    if len(encoded) > 8:
        raise LevelFormatError(f"{field_name} must be at most 8 characters.")


def _append_coord_list(out: bytearray, coords: List[Coord]) -> None:
    out.extend(struct.pack("<H", len(coords)))
    for coord in coords:
        out.extend(struct.pack("<HH", coord.x, coord.y))


def _read_coord_list(
    data: bytes, offset: int, max_size: int, name: str
) -> tuple[List[Coord], int]:
    if offset + 2 > len(data):
        raise LevelFormatError(f"Sublevel ends in count field ({name}).")
    count = struct.unpack_from("<H", data, offset)[0]
    offset += 2
    if count > max_size:
        raise LevelFormatError(f"{name} count {count} is greater than limit {max_size}.")
    coords: List[Coord] = []
    for _ in range(count):
        if offset + 4 > len(data):
            raise LevelFormatError(f"Sublevel ends in coordinates ({name}).")
        x, y = struct.unpack_from("<HH", data, offset)
        offset += 4
        coords.append(Coord(x=x, y=y))
    return coords, offset


def _encode_pascal8(text: str) -> bytes:
    clean = text.encode("ascii", errors="ignore")[:8]
    # String[8] in TP: length byte + up to 8 chars
    return bytes([len(clean)]) + clean + b"\x00" * (8 - len(clean))


def _decode_pascal8(raw9: bytes) -> str:
    if len(raw9) != 9:
        raise LevelFormatError("Pascal string must be exactly 9 bytes.")
    length = min(raw9[0], 8)
    return raw9[1 : 1 + length].decode("ascii", errors="ignore")
