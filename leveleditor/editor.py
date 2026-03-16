from __future__ import annotations

import argparse
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from pathlib import Path
from typing import Dict, List, Optional

from level_format import (
    Coord,
    LEVEL_HEIGHT,
    LEVEL_WIDTH,
    LevelFormatError,
    PackedLevel,
    SubLevel,
    load_packed_level,
    save_packed_level,
)
from sprite_loader import load_background_bank, load_sprite_bank


KNOWN_TILES = [0, 5, 6, 7, 8, 9, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 30]
TILE_COLORS: Dict[int, str] = {
    0: "#1e1e1e",
    5: "#5f7f32",
    6: "#698b39",
    7: "#739741",
    8: "#80a348",
    9: "#8caf4f",
    14: "#5d4a2f",
    15: "#7a613d",
    16: "#445d87",
    17: "#4c6896",
    18: "#5472a3",
    19: "#8a6f56",
    20: "#997b61",
    21: "#a8876c",
    22: "#b79579",
    23: "#c8a587",
    24: "#7b3e32",
    25: "#8d493a",
    30: "#505050",
}

OBJECT_DEFS = {
    "spin": ("Spider", 10, "#f54291"),
    "fleder": ("Bat", 10, "#b066ff"),
    "flaschen": ("Bottle", 10, "#39b5ff"),
    "mauer": ("Bomb Wall", 10, "#ff8f3f"),
    "skorpion": ("Scorpion", 10, "#f54e42"),
    "gbusch": ("Big Bush", 20, "#39d98a"),
    "kbusch": ("Small Bush", 20, "#67e86d"),
}

TILE_TO_SPRITE_INDEX = {
    5: 4,
    6: 5,
    7: 6,
    8: 7,
    9: 8,
    14: 13,
    15: 14,
    16: 15,
    17: 16,
    18: 17,
    19: 18,
    20: 19,
    21: 20,
    22: 21,
    23: 22,
    24: 23,
    25: 24,
}

# Only these tile IDs are visibly rendered in the original game draw loop.
VISIBLE_TILE_IDS = set(TILE_TO_SPRITE_INDEX.keys())

OBJECT_TO_SPRITE_INDEX = {
    "spin": 0,
    "fleder": 1,
    "flaschen": 3,
    "mauer": 9,
    "skorpion": 10,
    "gbusch": 11,
    "kbusch": 12,
}

# Draw offsets in source pixel units (taken from the original Pascal renderer).
TILE_DRAW_OFFSETS = {
    5: (0, -2),
    14: (0, 0),
    15: (-13, 0),
    16: (0, -1),
    17: (0, -1),
    18: (0, -1),
    24: (0, -1),
    25: (0, -2),
}


class LevelEditorApp(tk.Tk):
    def __init__(self, sprite_file: Optional[str] = None) -> None:
        super().__init__()
        self.title("Drake Snake Level Editor")
        self.geometry("1320x860")
        self.minsize(1180, 760)

        self.sprite_scale = 2
        self.cell_w = 16 * self.sprite_scale
        self.cell_h = 14 * self.sprite_scale
        self.sprite_file_path: Optional[Path] = Path(sprite_file).resolve() if sprite_file else None

        self.level_data: PackedLevel = PackedLevel.new_empty(1)
        self.current_index = 0
        self.current_file: Optional[Path] = None
        self.current_tile = 5
        self.edit_mode = tk.StringVar(value="tile")
        self.current_object = tk.StringVar(value="spin")
        self.sprite_images: Dict[int, tk.PhotoImage] = {}
        self.background_images: Dict[str, tk.PhotoImage] = {}
        self.use_sprite_assets = False
        self.sprite_status_var = tk.StringVar(value="")
        self.tile_preview_fallback = tk.PhotoImage(width=self.cell_w, height=self.cell_h)
        self.object_preview_fallback = tk.PhotoImage(
            width=max(16, self.cell_w // 2), height=max(14, self.cell_h // 2)
        )

        self._build_ui()
        self._load_sprites()
        self._refresh_all()

    def _build_ui(self) -> None:
        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)

        left = ttk.Frame(self, padding=8)
        left.grid(row=0, column=0, sticky="ns")
        left.rowconfigure(1, weight=1)

        ttk.Label(left, text="Sublevel").grid(row=0, column=0, sticky="w")
        self.sublevel_list = tk.Listbox(left, width=20, exportselection=False)
        self.sublevel_list.grid(row=1, column=0, sticky="ns", pady=(4, 6))
        self.sublevel_list.bind("<<ListboxSelect>>", self._on_sublevel_select)

        btn_frame = ttk.Frame(left)
        btn_frame.grid(row=2, column=0, sticky="ew")
        ttk.Button(btn_frame, text="+", width=4, command=self._add_sublevel).grid(
            row=0, column=0, padx=(0, 4)
        )
        ttk.Button(btn_frame, text="-", width=4, command=self._remove_sublevel).grid(
            row=0, column=1
        )

        center = ttk.Frame(self, padding=8)
        center.grid(row=0, column=1, sticky="nsew")
        center.columnconfigure(0, weight=1)
        center.rowconfigure(1, weight=1)

        toolbar = ttk.Frame(center)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        ttk.Button(toolbar, text="New", command=self._new_file).grid(row=0, column=0, padx=(0, 6))
        ttk.Button(toolbar, text="Open...", command=self._open_file).grid(
            row=0, column=1, padx=(0, 6)
        )
        ttk.Button(toolbar, text="Save", command=self._save_file).grid(
            row=0, column=2, padx=(0, 6)
        )
        ttk.Button(toolbar, text="Save As...", command=self._save_as_file).grid(
            row=0, column=3
        )

        self.canvas = tk.Canvas(center, background="#111111", highlightthickness=0)
        self.canvas.grid(row=1, column=0, sticky="nsew")
        self.canvas.bind("<Button-1>", self._on_canvas_left_click)
        self.canvas.bind("<Button-3>", self._on_canvas_right_click)

        right = ttk.Frame(self, padding=8)
        right.grid(row=0, column=2, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)

        self.right_canvas = tk.Canvas(right, highlightthickness=0, width=320)
        self.right_canvas.grid(row=0, column=0, sticky="nsew")
        right_scroll = ttk.Scrollbar(right, orient="vertical", command=self.right_canvas.yview)
        right_scroll.grid(row=0, column=1, sticky="ns")
        self.right_canvas.configure(yscrollcommand=right_scroll.set)

        right_inner = ttk.Frame(self.right_canvas)
        self.right_canvas_window = self.right_canvas.create_window((0, 0), window=right_inner, anchor="nw")
        right_inner.bind("<Configure>", self._on_right_frame_configure)
        self.right_canvas.bind("<Configure>", self._on_right_canvas_configure)
        self.right_canvas.bind("<Enter>", self._bind_right_mousewheel)
        self.right_canvas.bind("<Leave>", self._unbind_right_mousewheel)

        mode_frame = ttk.LabelFrame(right_inner, text="Mode", padding=8)
        mode_frame.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        ttk.Radiobutton(
            mode_frame,
            text="Tiles",
            value="tile",
            variable=self.edit_mode,
            command=self._on_mode_change,
        ).grid(row=0, column=0, sticky="w")
        ttk.Radiobutton(
            mode_frame,
            text="Objects",
            value="object",
            variable=self.edit_mode,
            command=self._on_mode_change,
        ).grid(row=1, column=0, sticky="w")

        self.tile_frame = ttk.LabelFrame(right_inner, text="Tiles", padding=8)
        self.tile_frame.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        self.tile_var = tk.StringVar(value=str(self.current_tile))
        self.tile_combo = ttk.Combobox(
            self.tile_frame,
            textvariable=self.tile_var,
            values=[str(t) for t in KNOWN_TILES],
            width=10,
            state="readonly",
        )
        self.tile_combo.grid(row=0, column=0, sticky="w")
        self.tile_combo.bind("<<ComboboxSelected>>", self._on_tile_change)
        self.tile_preview_label = ttk.Label(self.tile_frame, image=self.tile_preview_fallback)
        self.tile_preview_label.grid(row=0, column=1, sticky="w", padx=(8, 0))
        ttk.Label(self.tile_frame, textvariable=self.sprite_status_var).grid(
            row=1, column=0, sticky="w", pady=(6, 0)
        )

        self.obj_frame = ttk.LabelFrame(right_inner, text="Objects", padding=8)
        self.obj_frame.grid(row=2, column=0, sticky="ew", pady=(0, 8))
        ttk.Label(self.obj_frame, text="Type").grid(row=0, column=0, sticky="w")
        self.obj_combo = ttk.Combobox(
            self.obj_frame,
            textvariable=self.current_object,
            values=list(OBJECT_DEFS.keys()),
            width=12,
            state="readonly",
        )
        self.obj_combo.grid(row=1, column=0, sticky="w")
        self.obj_combo.bind("<<ComboboxSelected>>", self._on_object_change)
        self.object_preview_label = ttk.Label(self.obj_frame, image=self.object_preview_fallback)
        self.object_preview_label.grid(row=1, column=1, sticky="w", padx=(8, 0))

        self.obj_count_label = ttk.Label(self.obj_frame, text="")
        self.obj_count_label.grid(row=2, column=0, sticky="w", pady=(6, 0))
        ttk.Label(self.obj_frame, text="Left click: add, right click: remove").grid(
            row=3, column=0, sticky="w", pady=(4, 0)
        )

        self.object_list = tk.Listbox(self.obj_frame, width=26, height=10)
        self.object_list.grid(row=4, column=0, sticky="ew", pady=(6, 0))

        global_frame = ttk.LabelFrame(right_inner, text="Global", padding=8)
        global_frame.grid(row=3, column=0, sticky="ew", pady=(0, 8))
        ttk.Label(global_frame, text="Hero X").grid(row=0, column=0, sticky="w")
        ttk.Label(global_frame, text="Hero Y").grid(row=2, column=0, sticky="w")
        self.hero_x_var = tk.StringVar(value="0")
        self.hero_y_var = tk.StringVar(value="0")
        ttk.Entry(global_frame, textvariable=self.hero_x_var, width=10).grid(
            row=1, column=0, sticky="w", pady=(2, 6)
        )
        ttk.Entry(global_frame, textvariable=self.hero_y_var, width=10).grid(
            row=3, column=0, sticky="w", pady=(2, 0)
        )
        ttk.Button(global_frame, text="Apply Hero", command=self._apply_hero).grid(
            row=4, column=0, sticky="w", pady=(8, 0)
        )

        conn_frame = ttk.LabelFrame(right_inner, text="Connections (0 = none/fin)", padding=8)
        conn_frame.grid(row=4, column=0, sticky="ew", pady=(0, 8))
        self.conn_vars = {
            "links": tk.StringVar(value="0"),
            "rechts": tk.StringVar(value="0"),
            "oben": tk.StringVar(value="0"),
            "unten": tk.StringVar(value="0"),
        }
        labels = [("Left", "links"), ("Right", "rechts"), ("Up", "oben"), ("Down", "unten")]
        for idx, (label, key) in enumerate(labels):
            ttk.Label(conn_frame, text=label).grid(row=idx * 2, column=0, sticky="w")
            cb = ttk.Combobox(conn_frame, textvariable=self.conn_vars[key], width=8, state="readonly")
            cb.grid(row=idx * 2 + 1, column=0, sticky="w", pady=(2, 6))
            cb.bind("<<ComboboxSelected>>", lambda _e: self._apply_connections())
            setattr(self, f"conn_{key}_combo", cb)

        bg_frame = ttk.LabelFrame(right_inner, text="Optional Background", padding=8)
        bg_frame.grid(row=5, column=0, sticky="ew")
        self.bg_enabled = tk.BooleanVar(value=False)
        self.bg_name = tk.StringVar(value="")
        self.bg_x = tk.StringVar(value="0")
        self.bg_y = tk.StringVar(value="0")
        ttk.Checkbutton(
            bg_frame,
            text="enabled",
            variable=self.bg_enabled,
            command=self._apply_background,
        ).grid(row=0, column=0, sticky="w")
        ttk.Label(bg_frame, text="Name (max 8)").grid(row=1, column=0, sticky="w")
        self.bg_name_combo = ttk.Combobox(
            bg_frame, textvariable=self.bg_name, width=12, state="readonly"
        )
        self.bg_name_combo.grid(row=2, column=0, sticky="w")
        self.bg_name_combo.bind("<<ComboboxSelected>>", lambda _e: self._apply_background())
        ttk.Label(bg_frame, text="X / Y").grid(row=3, column=0, sticky="w", pady=(6, 0))
        coords = ttk.Frame(bg_frame)
        coords.grid(row=4, column=0, sticky="w")
        ttk.Entry(coords, textvariable=self.bg_x, width=6).grid(row=0, column=0, padx=(0, 4))
        ttk.Entry(coords, textvariable=self.bg_y, width=6).grid(row=0, column=1)
        ttk.Button(bg_frame, text="Apply Background", command=self._apply_background).grid(
            row=5, column=0, sticky="w", pady=(8, 0)
        )
        self._update_mode_panels()

    def _current_sublevel(self) -> SubLevel:
        return self.level_data.sublevels[self.current_index]

    def _refresh_all(self) -> None:
        self._refresh_sublevel_list()
        self._refresh_connection_choices()
        self._refresh_properties()
        self._draw_grid()
        self._refresh_object_list()
        self._update_object_preview()
        self._update_title()

    def _load_sprites(self) -> None:
        base_dir = Path(__file__).resolve().parent.parent
        distribution_dir = base_dir / "distribution"
        if self.sprite_file_path is not None and self.sprite_file_path.exists():
            self.sprite_images = load_sprite_bank(
                self,
                distribution_dir,
                scale=self.sprite_scale,
                sprite_file=self.sprite_file_path,
            )
            self.background_images = load_background_bank(
                self,
                distribution_dir,
                scale=self.sprite_scale,
                sprite_file=self.sprite_file_path,
            )
            self.use_sprite_assets = bool(self.sprite_images)
        else:
            self.sprite_images = {}
            self.background_images = {}
            self.use_sprite_assets = False

        bg_values = [""] + sorted(self.background_images.keys())
        self.bg_name_combo["values"] = bg_values
        if self.use_sprite_assets:
            bg_count = len(self.background_images)
            self.sprite_status_var.set(
                f"Loaded sprites: {len(self.sprite_images)}, backgrounds: {bg_count} (scale {self.sprite_scale}x)"
            )
        else:
            self.sprite_status_var.set("No sprite file loaded. Using colored tiles with numbers.")
        self._update_tile_preview()
        self._update_object_preview()

    def _on_right_frame_configure(self, _event: tk.Event) -> None:
        self.right_canvas.configure(scrollregion=self.right_canvas.bbox("all"))

    def _on_right_canvas_configure(self, event: tk.Event) -> None:
        self.right_canvas.itemconfigure(self.right_canvas_window, width=event.width)

    def _bind_right_mousewheel(self, _event: tk.Event) -> None:
        self.bind_all("<MouseWheel>", self._on_right_mousewheel)

    def _unbind_right_mousewheel(self, _event: tk.Event) -> None:
        self.unbind_all("<MouseWheel>")

    def _on_right_mousewheel(self, event: tk.Event) -> None:
        delta = int(-1 * (event.delta / 120))
        self.right_canvas.yview_scroll(delta, "units")

    def _on_mode_change(self) -> None:
        self._update_mode_panels()

    def _update_mode_panels(self) -> None:
        mode = self.edit_mode.get()
        if mode == "tile":
            self.tile_frame.grid()
            self.obj_frame.grid_remove()
        else:
            self.tile_frame.grid_remove()
            self.obj_frame.grid()
        self._on_right_frame_configure(None)

    def _refresh_sublevel_list(self) -> None:
        self.sublevel_list.delete(0, tk.END)
        for idx in range(len(self.level_data.sublevels)):
            self.sublevel_list.insert(tk.END, f"Sublevel {idx + 1:02d}")
        self.sublevel_list.selection_clear(0, tk.END)
        self.sublevel_list.selection_set(self.current_index)

    def _refresh_connection_choices(self) -> None:
        n = len(self.level_data.sublevels)
        choices = [str(i) for i in range(0, n + 1)]
        for key in ("links", "rechts", "oben", "unten"):
            combo = getattr(self, f"conn_{key}_combo")
            combo["values"] = choices

    def _refresh_properties(self) -> None:
        self.hero_x_var.set(str(self.level_data.hero_x))
        self.hero_y_var.set(str(self.level_data.hero_y))
        conn = self.level_data.connections[self.current_index]
        self.conn_vars["links"].set(str(conn[0]))
        self.conn_vars["rechts"].set(str(conn[1]))
        self.conn_vars["oben"].set(str(conn[2]))
        self.conn_vars["unten"].set(str(conn[3]))

        sub = self._current_sublevel()
        self.bg_enabled.set(sub.has_background)
        self.bg_name.set(_normalize_bg_name(sub.background_name))
        self.bg_x.set(str(sub.background_x))
        self.bg_y.set(str(sub.background_y))

    def _draw_grid(self) -> None:
        self.canvas.delete("all")
        sub = self._current_sublevel()

        # Draw optional per-sublevel background image first.
        if self.use_sprite_assets and sub.has_background:
            bg_key = _normalize_bg_name(sub.background_name)
            bg_img = self.background_images.get(bg_key)
            if bg_img is not None:
                self.canvas.create_image(
                    sub.background_x * self.sprite_scale,
                    sub.background_y * self.sprite_scale,
                    image=bg_img,
                    anchor="nw",
                )

        for y in range(LEVEL_HEIGHT):
            for x in range(LEVEL_WIDTH):
                idx = y * LEVEL_WIDTH + x
                tile = sub.grid[idx]
                x1 = x * self.cell_w
                y1 = y * self.cell_h
                x2 = x1 + self.cell_w
                y2 = y1 + self.cell_h
                if self.use_sprite_assets and tile in VISIBLE_TILE_IDS:
                    c = TILE_COLORS.get(tile, "#333333")
                    self.canvas.create_rectangle(x1, y1, x2, y2, fill=c, outline="#202020")
                elif self.use_sprite_assets:
                    # Non-visible logic tiles (e.g. 0, 30) are not drawn.
                    pass
                else:
                    c = TILE_COLORS.get(tile, "#2a2a2a")
                    self.canvas.create_rectangle(x1, y1, x2, y2, fill=c, outline="#202020")
                    self.canvas.create_text(
                        x1 + self.cell_w // 2,
                        y1 + self.cell_h // 2,
                        text=str(tile),
                        fill="#f0f0f0",
                        font=("Consolas", max(8, self.cell_w // 4)),
                    )
                sprite_idx = TILE_TO_SPRITE_INDEX.get(tile)
                if self.use_sprite_assets and sprite_idx is not None and sprite_idx in self.sprite_images:
                    img = self.sprite_images[sprite_idx]
                    dx, dy = TILE_DRAW_OFFSETS.get(tile, (0, 0))
                    self.canvas.create_image(
                        x1 + dx * self.sprite_scale,
                        y1 + dy * self.sprite_scale,
                        image=img,
                        anchor="nw",
                    )

        for obj_key, (_, _max_count, color) in OBJECT_DEFS.items():
            for coord in self._get_object_list(obj_key):
                px = int(round((coord.x / 16.0) * self.cell_w))
                py = int(round((coord.y / 14.0) * self.cell_h))
                sprite_idx = OBJECT_TO_SPRITE_INDEX.get(obj_key)
                if self.use_sprite_assets and sprite_idx is not None and sprite_idx in self.sprite_images:
                    img = self.sprite_images[sprite_idx]
                    self.canvas.create_image(px, py, image=img, anchor="nw")
                else:
                    cx = px + self.cell_w // 2
                    cy = py + self.cell_h // 2
                    self.canvas.create_oval(cx - 4, cy - 4, cx + 4, cy + 4, fill=color, outline="")
        self.canvas.config(width=LEVEL_WIDTH * self.cell_w, height=LEVEL_HEIGHT * self.cell_h)

    def _on_sublevel_select(self, _event: tk.Event) -> None:
        sel = self.sublevel_list.curselection()
        if not sel:
            return
        self.current_index = sel[0]
        self._refresh_properties()
        self._refresh_object_list()
        self._draw_grid()

    def _on_tile_change(self, _event: tk.Event) -> None:
        self.current_tile = int(self.tile_var.get())
        self._update_tile_preview()

    def _on_object_change(self, _event: tk.Event) -> None:
        self._refresh_object_list()
        self._update_object_preview()

    def _update_tile_preview(self) -> None:
        sprite_idx = TILE_TO_SPRITE_INDEX.get(self.current_tile)
        if self.use_sprite_assets and sprite_idx is not None and sprite_idx in self.sprite_images:
            self.tile_preview_label.configure(image=self.sprite_images[sprite_idx])
        else:
            color = TILE_COLORS.get(self.current_tile, "#444444")
            self.tile_preview_fallback = tk.PhotoImage(width=self.cell_w, height=self.cell_h)
            self.tile_preview_fallback.put(color, to=(0, 0, self.cell_w, self.cell_h))
            self.tile_preview_label.configure(image=self.tile_preview_fallback)

    def _update_object_preview(self) -> None:
        obj_key = self.current_object.get()
        sprite_idx = OBJECT_TO_SPRITE_INDEX.get(obj_key)
        if self.use_sprite_assets and sprite_idx is not None and sprite_idx in self.sprite_images:
            self.object_preview_label.configure(image=self.sprite_images[sprite_idx])
            return

        _, _, color = OBJECT_DEFS[obj_key]
        w = max(16, self.cell_w // 2)
        h = max(14, self.cell_h // 2)
        self.object_preview_fallback = tk.PhotoImage(width=w, height=h)
        self.object_preview_fallback.put("#111111", to=(0, 0, w, h))
        margin = 2
        self.object_preview_fallback.put(color, to=(margin, margin, w - margin, h - margin))
        self.object_preview_label.configure(image=self.object_preview_fallback)

    def _on_canvas_left_click(self, event: tk.Event) -> None:
        x = event.x // self.cell_w
        y = event.y // self.cell_h
        if not (0 <= x < LEVEL_WIDTH and 0 <= y < LEVEL_HEIGHT):
            return

        if self.edit_mode.get() == "tile":
            idx = y * LEVEL_WIDTH + x
            self._current_sublevel().grid[idx] = self.current_tile
        else:
            self._add_object_at(x, y)
        self._draw_grid()
        self._refresh_object_list()

    def _on_canvas_right_click(self, event: tk.Event) -> None:
        if self.edit_mode.get() != "object":
            return
        x = event.x // self.cell_w
        y = event.y // self.cell_h
        if not (0 <= x < LEVEL_WIDTH and 0 <= y < LEVEL_HEIGHT):
            return
        self._remove_object_at(x, y)
        self._draw_grid()
        self._refresh_object_list()

    def _add_object_at(self, grid_x: int, grid_y: int) -> None:
        obj_key = self.current_object.get()
        obj_name, obj_limit, _ = OBJECT_DEFS[obj_key]
        target = self._get_object_list(obj_key)
        if len(target) >= obj_limit:
            messagebox.showwarning("Limit reached", f"{obj_name}: max {obj_limit} entries.")
            return
        px = grid_x * 16
        py = grid_y * 14
        target.append(Coord(px, py))

    def _remove_object_at(self, grid_x: int, grid_y: int) -> None:
        obj_key = self.current_object.get()
        target = self._get_object_list(obj_key)
        if not target:
            return
        px = grid_x * 16
        py = grid_y * 14
        remove_idx = None
        for i, coord in enumerate(target):
            if coord.x == px and coord.y == py:
                remove_idx = i
                break
        if remove_idx is not None:
            target.pop(remove_idx)

    def _get_object_list(self, obj_key: str) -> List[Coord]:
        sub = self._current_sublevel()
        return getattr(sub, obj_key)

    def _refresh_object_list(self) -> None:
        obj_key = self.current_object.get()
        obj_name, obj_limit, _ = OBJECT_DEFS[obj_key]
        coords = self._get_object_list(obj_key)
        self.obj_count_label.config(text=f"{obj_name}: {len(coords)} / {obj_limit}")
        self.object_list.delete(0, tk.END)
        for i, coord in enumerate(coords, start=1):
            self.object_list.insert(tk.END, f"{i:02d}: x={coord.x:3d} y={coord.y:3d}")

    def _apply_hero(self) -> None:
        try:
            self.level_data.hero_x = int(self.hero_x_var.get())
            self.level_data.hero_y = int(self.hero_y_var.get())
            self.level_data.validate()
        except Exception as exc:
            messagebox.showerror("Invalid hero coordinates", str(exc))

    def _apply_connections(self) -> None:
        n = len(self.level_data.sublevels)
        try:
            values = (
                int(self.conn_vars["links"].get()),
                int(self.conn_vars["rechts"].get()),
                int(self.conn_vars["oben"].get()),
                int(self.conn_vars["unten"].get()),
            )
            for value in values:
                if not 0 <= value <= n:
                    raise ValueError(f"Connection value {value} outside 0..{n}")
            self.level_data.connections[self.current_index] = values
        except Exception as exc:
            messagebox.showerror("Invalid connections", str(exc))

    def _apply_background(self) -> None:
        sub = self._current_sublevel()
        sub.has_background = bool(self.bg_enabled.get())
        sub.background_name = _normalize_bg_name(self.bg_name.get())[:8]
        try:
            sub.background_x = int(self.bg_x.get())
            sub.background_y = int(self.bg_y.get())
            sub.validate()
        except Exception as exc:
            messagebox.showerror("Invalid background", str(exc))

    def _add_sublevel(self) -> None:
        if len(self.level_data.sublevels) >= 25:
            messagebox.showwarning("Limit", "Maximum of 25 sublevels allowed.")
            return
        self.level_data.sublevels.append(SubLevel())
        self.level_data.connections.append((0, 0, 0, 0))
        self.current_index = len(self.level_data.sublevels) - 1
        self._refresh_all()

    def _remove_sublevel(self) -> None:
        if len(self.level_data.sublevels) <= 1:
            messagebox.showwarning("Not possible", "At least one sublevel is required.")
            return
        idx = self.current_index + 1
        if not messagebox.askyesno("Delete", f"Delete sublevel {idx}?"):
            return
        self.level_data.sublevels.pop(self.current_index)
        self.level_data.connections.pop(self.current_index)

        n = len(self.level_data.sublevels)
        fixed: List[tuple[int, int, int, int]] = []
        for conn in self.level_data.connections:
            vals = []
            for v in conn:
                if v == idx:
                    vals.append(0)
                elif v > idx:
                    vals.append(v - 1)
                else:
                    vals.append(v)
            vals = [0 if x < 0 or x > n else x for x in vals]
            fixed.append((vals[0], vals[1], vals[2], vals[3]))
        self.level_data.connections = fixed

        self.current_index = max(0, min(self.current_index, n - 1))
        self._refresh_all()

    def _new_file(self) -> None:
        self.level_data = PackedLevel.new_empty(1)
        self.current_index = 0
        self.current_file = None
        self._refresh_all()

    def _open_file(self) -> None:
        path = filedialog.askopenfilename(
            title="Open level file",
            filetypes=[("Drake Snake Level", "*.lvl"), ("All files", "*.*")],
        )
        if not path:
            return
        try:
            self.level_data = load_packed_level(path)
            self.current_index = 0
            self.current_file = Path(path)
            self._refresh_all()
        except Exception as exc:
            messagebox.showerror("Load failed", str(exc))

    def _save_file(self) -> None:
        if self.current_file is None:
            self._save_as_file()
            return
        self._save_to_path(self.current_file)

    def _save_as_file(self) -> None:
        path = filedialog.asksaveasfilename(
            title="Save level file",
            defaultextension=".lvl",
            filetypes=[("Drake Snake Level", "*.lvl"), ("All files", "*.*")],
        )
        if not path:
            return
        self._save_to_path(Path(path))

    def _save_to_path(self, path: Path) -> None:
        try:
            self._apply_hero()
            self._apply_connections()
            self._apply_background()
            self.level_data.validate()
            save_packed_level(path, self.level_data)
            self.current_file = path
            self._update_title()
            messagebox.showinfo("Saved", f"File saved:\n{path}")
        except (LevelFormatError, ValueError) as exc:
            messagebox.showerror("Save failed", str(exc))

    def _update_title(self) -> None:
        name = self.current_file.name if self.current_file else "(new)"
        self.title(f"Drake Snake Level Editor - {name}")


def _normalize_bg_name(name: str) -> str:
    clean = name.strip().lower()
    if clean.endswith(".bld"):
        clean = clean[:-4]
    return clean


def main() -> None:
    parser = argparse.ArgumentParser(description="Drake Snake Level Editor")
    parser.add_argument(
        "--sprite-file",
        dest="sprite_file",
        default=None,
        help="Optional path to packed sprite file (e.g. distribution/drake.spr).",
    )
    args = parser.parse_args()
    app = LevelEditorApp(sprite_file=args.sprite_file)
    app.mainloop()


if __name__ == "__main__":
    main()
