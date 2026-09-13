"""Rebuild the native icon from the geometry in assets/app-icon.svg.

Optional artwork-only dependency: Pillow. Not needed to build the app.
Run: python tool/build_icon.py
"""

from pathlib import Path
from PIL import Image, ImageDraw

SCALE = 4
image = Image.new("RGBA", (256 * SCALE, 256 * SCALE))
draw = ImageDraw.Draw(image)


def box(values):
    return tuple(value * SCALE for value in values)


draw.rounded_rectangle(box((0, 0, 255, 255)), radius=58 * SCALE, fill="#007d72")
for points in (
    [(128, 194), (128, 69)],
    [(128, 141), (85, 112), (85, 91)],
    [(128, 158), (171, 130), (171, 102)],
):
    draw.line([box(p) for p in points], fill="white", width=14 * SCALE, joint="curve")
    for x, y in points:
        draw.ellipse(box((x - 7, y - 7, x + 7, y + 7)), fill="white")
draw.ellipse(box((109, 176, 147, 214)), fill="white")
draw.polygon([box(p) for p in [(128, 40), (106, 74), (150, 74)]], fill="white")
draw.ellipse(box((70, 65, 100, 95)), fill="white")
draw.rounded_rectangle(box((156, 77, 186, 107)), radius=3 * SCALE, fill="white")
output = Path(__file__).resolve().parents[1] / "windows/runner/resources/app_icon.ico"
image.resize((256, 256), Image.Resampling.LANCZOS).save(
    output, sizes=[(n, n) for n in (16, 32, 48, 64, 128, 256)]
)
print(output)
