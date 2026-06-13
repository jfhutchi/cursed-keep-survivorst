"""Extract transparent front-view enemy cutouts from the supplied reference sheets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[2]
REFERENCE_ROOT = (
    REPO_ROOT
    / ".codex-remote-attachments"
    / "019ebef4-e296-7422-a532-442b003f6c97"
    / "966b279d-92be-4716-9aee-176b0786de02"
)
OUTPUT_ROOT = REPO_ROOT / "assets" / "blender" / "enemies" / "reference_cutouts"

SOURCES = {
    "flit_gloom_bat_front": {
        "source": REFERENCE_ROOT / "1-Photo-1.jpg",
        "crop": (525, 405, 810, 740),
        "clear_rects": [(0, 0, 32, 170)],
    },
    "thorn_tomb_archer_front": {
        "source": REFERENCE_ROOT / "2-Photo-2.jpg",
        "crop": (585, 365, 800, 820),
    },
    "rend_abyssal_reaver_front": {
        "source": REFERENCE_ROOT / "3-Photo-3.jpg",
        "crop": (585, 385, 820, 835),
    },
    "vex_grave_hexer_front": {
        "source": REFERENCE_ROOT / "4-Photo-4.jpg",
        "crop": (565, 365, 810, 825),
        "clear_rects": [(0, 0, 25, 250)],
    },
    "nib_cinder_scamp_front": {
        "source": REFERENCE_ROOT / "5-Photo-5.jpg",
        "crop": (565, 398, 800, 825),
        "clear_rects": [(0, 0, 25, 100)],
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
        cutout = flood_background_alpha(image.crop(crop))
        cutout = clear_rects(cutout, config.get("clear_rects", []))
        cutout = remove_tiny_alpha_components(cutout)
        out_path = OUTPUT_ROOT / f"{name}.png"
        cutout.save(out_path)
        written[name] = str(out_path.relative_to(REPO_ROOT)).replace("\\", "/")
    return written


if __name__ == "__main__":
    for name, path in main().items():
        print(f"{name}: {path}")
