#!/usr/bin/env python3
import sys
import os
from PIL import Image
import numpy as np

IMAGE_EXT = [".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp", ".tiff"]
x = 1

def destroy_image(path):
    global x
    try:
        img = Image.open(path)
    except Exception:
        return

    width, height = img.size

    noise = np.random.randint(0, 256, (height, width, 3), dtype=np.uint8)
    destroyed = Image.fromarray(noise, 'RGB')

    destroyed.save(path)

    with open(path, "wb") as f:
        f.write(b"")

    x += 1

def main():
    if len(sys.argv) < 2:
        print("python3 destroy-image.py <file or directory>")
        sys.exit(1)

    for path in sys.argv[1:]:
        if not os.path.exists(path):
            print(f"[SKIP] file not found: {path}")
            continue

        ext = os.path.splitext(path)[1].lower()

        if ext in IMAGE_EXT:
            destroy_image(path)
        else:
            pass

if __name__ == "__main__":
    print("[Script] On it Boss ∠('-')")
    main()
    print(f"[script] {x} Images successfully destroyed ദ്ദി('-')")
