"""Extract transparent front-view hero cutouts from the supplied reference sheets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[2]
REFERENCE_ROOT = REPO_ROOT / ".codex-remote-attachments" / "019ebef4-e296-7422-a532-442b003f6c97" / "1253f447-90ca-476b-9be4-4fa61f75d4ce"
OUTPUT_ROOT = REPO_ROOT / "assets" / "blender" / "heroes" / "reference_cutouts"

SOURCES = {
    "kaelan_front": {
        "source": REFERENCE_ROOT / "1-Photo-1.jpg",
        "crop": (608, 372, 803, 855),
        "clear_rects": [(0, 0, 45, 95)],
    },
    "lyria_front": {
        "source": REFERENCE_ROOT / "2-Photo-2.jpg",
        "crop": (585, 372, 765, 860),
    },
}


def is_gray_background(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, _a = pixel
    max_delta = max(abs(r - g), abs(g - b), abs(r - b))
    return max_delta < 28 and 42 <= r <= 220 and 42 <= g <= 220 and 42 <= b <= 220


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


def main() -> dict[str, str]:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    written: dict[str, str] = {}
    for name, config in SOURCES.items():
        source = config["source"]
        crop = config["crop"]
        image = Image.open(source)
        cutout = flood_background_alpha(image.crop(crop))
        cutout = clear_rects(cutout, config.get("clear_rects", []))
        out_path = OUTPUT_ROOT / f"{name}.png"
        cutout.save(out_path)
        written[name] = str(out_path.relative_to(REPO_ROOT)).replace("\\", "/")
    return written


if __name__ == "__main__":
    for name, path in main().items():
        print(f"{name}: {path}")
