"""Prépare les photos de la boutique : détourage automatique (rembg), recadrage
centré, fond transparent, format carré prêt pour l'app.

Utilisation :
    1. Mettre les photos d'un article dans D:/Yan/boutique/<id-article>/
       (ex. D:/Yan/boutique/af1-blanc/1.jpg, 2.jpg, ...)
    2. python tools/process_products.py            (détourage, fond transparent, .png)
       python tools/process_products.py --cadre    (photo de studio gardée entière, .jpg)
    3. Les images détourées arrivent dans app/assets/products/<id-article>-<n>.png
    4. Dans app/lib/data/store_catalog.dart, mettre `photoCount: <n>` sur l'article.

L'<id-article> doit correspondre au champ `id` du produit (ex. af1-blanc,
af1-noir, maillot-domicile, maillot-exterieur).
"""

from pathlib import Path
import sys

from PIL import Image

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
# --cadre : garde la photo entière (fond de studio compris) au lieu de détourer.
FRAMED = "--cadre" in sys.argv
FRAME_SIZE = 900
SOURCE = Path(ARGS[0]) if ARGS else Path("D:/Yan/boutique")
TARGET = Path(__file__).resolve().parent.parent / "app" / "assets" / "products"
SIZE = 1000          # côté du carré final, en pixels
MARGIN = 0.08        # marge autour du produit
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".heic"}


def process(src: Path, dst: Path, session) -> None:
    image = Image.open(src).convert("RGBA")
    from rembg import remove
    cut = remove(image, session=session)

    # Recadre au plus près du produit, puis le centre dans un carré transparent.
    box = cut.getbbox()
    if box is None:
        print(f"  ! rien détecté dans {src.name}, ignoré")
        return
    cut = cut.crop(box)
    inner = int(SIZE * (1 - 2 * MARGIN))
    cut.thumbnail((inner, inner), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(cut, ((SIZE - cut.width) // 2, (SIZE - cut.height) // 2), cut)

    dst.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst, optimize=True)
    print(f"  ok {dst.relative_to(TARGET.parent.parent)}")


def frame(src: Path, dst: Path) -> None:
    """Photo gardée telle quelle : carré centré, redimensionné, en JPEG."""
    image = Image.open(src).convert("RGB")
    side = min(image.size)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    image = image.crop((left, top, left + side, top + side))
    image = image.resize((FRAME_SIZE, FRAME_SIZE), Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    image.save(dst, quality=86, optimize=True)
    print(f"  ok {dst.relative_to(TARGET.parent.parent)}")


def main() -> None:
    if not SOURCE.exists():
        sys.exit(f"Dossier introuvable : {SOURCE}")
    if FRAMED:
        for folder in sorted(p for p in SOURCE.iterdir() if p.is_dir()):
            photos = sorted(p for p in folder.iterdir() if p.suffix.lower() in EXTENSIONS)
            for i, photo in enumerate(photos, start=1):
                frame(photo, TARGET / f"{folder.name}-{i}.jpg")
        return
    from rembg import new_session
    session = new_session("isnet-general-use")
    for folder in sorted(p for p in SOURCE.iterdir() if p.is_dir()):
        photos = sorted(p for p in folder.iterdir() if p.suffix.lower() in EXTENSIONS)
        if not photos:
            continue
        print(f"{folder.name} : {len(photos)} photo(s)")
        for i, photo in enumerate(photos, start=1):
            process(photo, TARGET / f"{folder.name}-{i}.png", session)


if __name__ == "__main__":
    main()
