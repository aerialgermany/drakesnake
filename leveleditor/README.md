# Drake Snake Level Editor

Standalone editor for the packed `level*.lvl` format.

## Start

From repository root:

```powershell
python leveleditor/editor.py
```

Optional sprite file argument:

```powershell
python leveleditor/editor.py --sprite-file "drake.spr"
```

## Features

- Load and save packed `*.lvl` files
- Edit individual sublevels
- Tile editing on a 20x28 grid
- Object editing for:
  - `spin`, `fleder`, `flaschen`, `mauer`, `skorpion` (max 10 each)
  - `gbusch`, `kbusch` (max 20 each)
- Global hero spawn coordinates
- Connection matrix per sublevel (`left/right/up/down`, `0 = none/fin`)
- Optional background block (`has_background`, `name`, `x/y`)
- Background preview in the editor canvas for compatible `.bld` files
- Background name dropdown populated from `distribution/*.bld`
- Tile and object preview thumbnails next to selection boxes
- Optional sprite rendering:
  - Enable with `--sprite-file`
  - If the file is not provided or missing, the editor uses colored boxes and tile IDs
- `.bld` support:
  - Raw indexed images with header `[u16 width][u16 height][pixels...]`
  - Files with other legacy/compressed formats are currently skipped

## Controls

- **Tile mode**: left click sets the selected tile ID
- **Object mode**:
  - choose object type (`spin`, `fleder`, ...)
  - left click adds object at the grid position (stored as pixel coordinates)
  - right click removes object at the grid position

## Notes

- The editor is intentionally format-compatible with the original game data and validates hard limits.
- Roundtrip (load -> save without changes) is byte-identical for the shipped level files.
