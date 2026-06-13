"""Extract transparent front-view cutouts for the second supplied enemy batch."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[2]
REFERENCE_ROOT = (
    REPO_ROOT
    / ".codex-remote-attachments"
    / "019ebef4-e296-7422-a532-442b003f6c97"
    / "a20fe249-43f0-4686-92e5-5ff285e747f9"
)
OUTPUT_ROOT = REPO_ROOT / "assets" / "blender" / "enemies" / "reference_cutouts"

SOURCES = {
    "shade_dusk_wraith_front": {
        "source": REFERENCE_ROOT / "1-Photo-1.jpg",
        "crop": (570, 385, 805, 860),
        "clear_rects": [(0, 0, 42, 95)],
    },
    "maw_slag_hound_front": {
        "source": REFERENCE_ROOT / "2-Photo-2.jpg",
        "crop": (565, 395, 795, 775),
        "clear_rects": [(200, 70, 235, 145), (0, 130, 10, 170)],
        "min_area": 300,
    },
    "bulwark_iron_husk_front": {
        "source": REFERENCE_ROOT / "3-Photo-3.jpg",
        "crop": (570, 405, 825, 825),
        "clear_rects": [(0, 0, 52, 155)],
    },
    "glob_rotspore_spitter_front": {
        "source": REFERENCE_ROOT / "4-Photo-4.jpg",
        "crop": (560, 370, 810, 800),
        "clear_rects": [(0, 0, 48, 190), (95, 0, 215, 36)],
    },
    "rattle_bone_drudge_front": {
        "source": REFERENCE_ROOT / "5-Photo-5.jpg",
        "crop": (535, 360, 790, 842),
        "clear_rects": [(0, 0, 18, 105)],
        "gray_clear_rects": [(74, 292, 154, 437)],
        "post_clear_rects": [(210, 300, 255, 360)],
        "edge_color_tolerance": 46,
    },
}


def is_gray_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _a = pixel
    max_delta = max(abs(r - g), abs(g - b), abs(r - b))
    return max_delta < 30 and 38 <= r <= 225 and 38 <= g <= 225 and 38 <= b <= 225


def flood_background_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or x < 0 or y < 0 or x >= width or y >= height:
            continue
        visited.add((x, y))
        if not is_gray_background(pixels[x, y]):
            continue
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    alpha_bbox = rgba.getbbox()
    if alpha_bbox is None:
        return rgba
    left, top, right, bottom = alpha_bbox
    pad = 10
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(width, right + pad)
    bottom = min(height, bottom + pad)
    return rgba.crop((left, top, right, bottom))


def flood_edge_color_alpha(image: Image.Image, tolerance: float) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    border: list[tuple[int, int, int]] = []
    for x in range(width):
        border.append(pixels[x, 0][:3])
        border.append(pixels[x, height - 1][:3])
    for y in range(height):
        border.append(pixels[0, y][:3])
        border.append(pixels[width - 1, y][:3])

    channels = list(zip(*border))
    target = tuple(sorted(channel)[len(channel) // 2] for channel in channels)
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    def close_to_background(pixel: tuple[int, int, int, int]) -> bool:
        r, g, b, _a = pixel
        dr = r - target[0]
        dg = g - target[1]
        db = b - target[2]
        return (dr * dr + dg * dg + db * db) ** 0.5 <= tolerance

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or x < 0 or y < 0 or x >= width or y >= height:
            continue
        visited.add((x, y))
        if not close_to_background(pixels[x, y]):
            continue
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    alpha_bbox = rgba.getbbox()
    if alpha_bbox is None:
        return rgba
    left, top, right, bottom = alpha_bbox
    pad = 10
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(width, right + pad)
    bottom = min(height, bottom + pad)
    return rgba.crop((left, top, right, bottom))


def clear_rects(image: Image.Image, rects: list[tuple[int, int, int, int]]) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for left, top, right, bottom in rects:
        for y in range(max(0, top), min(height, bottom)):
            for x in range(max(0, left), min(width, right)):
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return rgba


def clear_gray_background_rects(image: Image.Image, rects: list[tuple[int, int, int, int]]) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for left, top, right, bottom in rects:
        for y in range(max(0, top), min(height, bottom)):
            for x in range(max(0, left), min(width, right)):
                r, g, b, a = pixels[x, y]
                if a == 0:
                    continue
                max_delta = max(abs(r - g), abs(g - b), abs(r - b))
                if max_delta < 20 and 55 <= r <= 165 and 55 <= g <= 165 and 55 <= b <= 165:
                    pixels[x, y] = (r, g, b, 0)
    return rgba


def trim_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha_bbox = rgba.getbbox()
    if alpha_bbox is None:
        return rgba
    return rgba.crop(alpha_bbox)


def remove_tiny_alpha_components(image: Image.Image, min_area: int = 25) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    visited: set[tuple[int, int]] = set()

    for start_y in range(height):
        for start_x in range(width):
            if (start_x, start_y) in visited or pixels[start_x, start_y][3] == 0:
                continue
            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            component: list[tuple[int, int]] = []
            visited.add((start_x, start_y))
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for next_x, next_y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if (
                        0 <= next_x < width
                        and 0 <= next_y < height
                        and (next_x, next_y) not in visited
                        and pixels[next_x, next_y][3] != 0
                    ):
                        visited.add((next_x, next_y))
                        queue.append((next_x, next_y))

            if len(component) < min_area:
                for x, y in component:
                    r, g, b, _a = pixels[x, y]
                    pixels[x, y] = (r, g, b, 0)

    alpha_bbox = rgba.getbbox()
    if alpha_bbox is None:
        return rgba
    return rgba.crop(alpha_bbox)


def main() -> dict[str, str]:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    written: dict[str, str] = {}
    for name, config in SOURCES.items():
        source = config["source"]
        crop = config["crop"]
        image = Image.open(source)
        cropped = image.crop(crop)
        if "edge_color_tolerance" in config:
            cutout = flood_edge_color_alpha(cropped, config["edge_color_tolerance"])
        else:
            cutout = flood_background_alpha(cropped)
        cutout = clear_rects(cutout, config.get("clear_rects", []))
        cutout = remove_tiny_alpha_components(cutout, min_area=config.get("min_area", 25))
        cutout = clear_gray_background_rects(cutout, config.get("gray_clear_rects", []))
        cutout = clear_rects(cutout, config.get("post_clear_rects", []))
        cutout = trim_to_alpha(cutout)
        out_path = OUTPUT_ROOT / f"{name}.png"
        cutout.save(out_path)
        written[name] = str(out_path.relative_to(REPO_ROOT)).replace("\\", "/")
    return written


if __name__ == "__main__":
    for name, path in main().items():
        print(f"{name}: {path}")
