#!/usr/bin/env python3
"""
Generate 3D printable STL files from Tesla custom wrap PNG designs.

Converts a wrap PNG into an embossed 3D model: a flat base plate with the
wrap pattern raised as a heightmap on the top surface. The result is a
watertight binary STL ready for slicing and printing.

Usage:
    python generate_3d_print.py <wrap.png> [options]

Examples:
    python generate_3d_print.py cybertruck/example/Doge.png
    python generate_3d_print.py model3/example/Sakura.png -o sakura_plate.stl
    python generate_3d_print.py modely/example/Camo_Blue.png --size 100 --height 4
"""

import argparse
import struct
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Missing dependencies. Run:  pip install -r requirements.txt", file=sys.stderr)
    sys.exit(1)


def load_heightmap(image_path: Path, resolution: int) -> np.ndarray:
    """Load a wrap PNG and return a normalised float32 heightmap [0..1]."""
    img = Image.open(image_path).convert("L")
    img = img.resize((resolution, resolution), Image.LANCZOS)
    return np.array(img, dtype=np.float32) / 255.0


def _normal(v0, v1, v2):
    """Return the unit normal of a triangle, falling back to (0,0,1) if degenerate."""
    a = np.asarray(v1) - np.asarray(v0)
    b = np.asarray(v2) - np.asarray(v0)
    n = np.cross(a, b)
    length = np.linalg.norm(n)
    return (n / length) if length > 1e-12 else np.array([0.0, 0.0, 1.0])


def _pack_triangle(f, n, v0, v1, v2):
    """Write one binary STL triangle (50 bytes)."""
    f.write(struct.pack("<3f", *n))
    f.write(struct.pack("<3f", *v0))
    f.write(struct.pack("<3f", *v1))
    f.write(struct.pack("<3f", *v2))
    f.write(struct.pack("<H", 0))


def generate_stl(
    heightmap: np.ndarray,
    output_path: Path,
    plate_size_mm: float,
    base_mm: float,
    emboss_mm: float,
) -> int:
    """
    Build a watertight binary STL from a 2-D heightmap.

    The model is a rectangular plate whose top surface is embossed according
    to the heightmap.  All six faces (top, bottom, four sides) are closed so
    the mesh is manifold and ready for any slicer.

    Returns the number of triangles written.
    """
    rows, cols = heightmap.shape
    cell = plate_size_mm / (rows - 1)

    # Pre-compute Z values for every grid vertex
    z_top = base_mm + heightmap * emboss_mm  # shape (rows, cols)

    triangles = []

    def quad(v00, v10, v01, v11):
        """Split a quad into two CCW triangles (as seen from outside)."""
        triangles.append((v00, v10, v01))
        triangles.append((v10, v11, v01))

    # --- Top surface (embossed heightmap) ---
    for r in range(rows - 1):
        for c in range(cols - 1):
            x0, y0 = c * cell, r * cell
            x1, y1 = (c + 1) * cell, (r + 1) * cell
            quad(
                (x0, y0, z_top[r,     c    ]),
                (x1, y0, z_top[r,     c + 1]),
                (x0, y1, z_top[r + 1, c    ]),
                (x1, y1, z_top[r + 1, c + 1]),
            )

    W = (cols - 1) * cell
    H = (rows - 1) * cell

    # --- Bottom face (flat, outward normal = -Z → CW winding from above) ---
    triangles.append(((0, 0, 0), (0, H, 0), (W, 0, 0)))
    triangles.append(((W, 0, 0), (0, H, 0), (W, H, 0)))

    # --- Four side walls ---
    # Front edge (y=0, outward normal = -Y)
    for c in range(cols - 1):
        x0, x1 = c * cell, (c + 1) * cell
        z0, z1 = z_top[0, c], z_top[0, c + 1]
        triangles.append(((x1, 0, 0), (x0, 0, 0), (x0, 0, z0)))
        triangles.append(((x1, 0, 0), (x0, 0, z0), (x1, 0, z1)))

    # Back edge (y=H, outward normal = +Y)
    for c in range(cols - 1):
        x0, x1 = c * cell, (c + 1) * cell
        z0, z1 = z_top[rows - 1, c], z_top[rows - 1, c + 1]
        triangles.append(((x0, H, 0), (x1, H, 0), (x0, H, z0)))
        triangles.append(((x0, H, z0), (x1, H, 0), (x1, H, z1)))

    # Left edge (x=0, outward normal = -X)
    for r in range(rows - 1):
        y0, y1 = r * cell, (r + 1) * cell
        z0, z1 = z_top[r, 0], z_top[r + 1, 0]
        triangles.append(((0, y0, 0), (0, y1, 0), (0, y0, z0)))
        triangles.append(((0, y0, z0), (0, y1, 0), (0, y1, z1)))

    # Right edge (x=W, outward normal = +X)
    for r in range(rows - 1):
        y0, y1 = r * cell, (r + 1) * cell
        z0, z1 = z_top[r, cols - 1], z_top[r + 1, cols - 1]
        triangles.append(((W, y1, 0), (W, y0, 0), (W, y0, z0)))
        triangles.append(((W, y1, 0), (W, y0, z0), (W, y1, z1)))

    # --- Write binary STL ---
    header = b"Tesla wrap 3D print - github.com/anthonysolo419-eng/custom-wraps"
    with open(output_path, "wb") as f:
        f.write(header[:80].ljust(80, b"\x00"))
        f.write(struct.pack("<I", len(triangles)))
        for v0, v1, v2 in triangles:
            n = _normal(v0, v1, v2)
            _pack_triangle(f, n, v0, v1, v2)

    return len(triangles)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a Tesla wrap PNG into a 3D-printable STL file.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("input", help="Wrap PNG file to convert")
    parser.add_argument(
        "-o", "--output",
        help="Output STL path (default: same name as input with .stl extension)",
    )
    parser.add_argument(
        "--size", type=float, default=80.0, metavar="MM",
        help="Plate width/height in millimetres",
    )
    parser.add_argument(
        "--base", type=float, default=2.0, metavar="MM",
        help="Flat base thickness in millimetres",
    )
    parser.add_argument(
        "--height", type=float, default=3.0, metavar="MM",
        help="Maximum emboss height in millimetres",
    )
    parser.add_argument(
        "--resolution", type=int, default=128, metavar="N",
        help="Heightmap grid resolution (NxN vertices); higher = more detail, larger file",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output) if args.output else input_path.with_suffix(".stl")

    print(f"Input  : {input_path}")
    print(f"Output : {output_path}")
    print(f"Plate  : {args.size} x {args.size} mm  |  base {args.base} mm  |  emboss {args.height} mm")
    print(f"Grid   : {args.resolution} x {args.resolution}")

    heightmap = load_heightmap(input_path, args.resolution)
    n_tris = generate_stl(heightmap, output_path, args.size, args.base, args.height)

    file_kb = output_path.stat().st_size / 1024
    print(f"Done   : {n_tris:,} triangles, {file_kb:.0f} KB → {output_path}")


if __name__ == "__main__":
    main()
