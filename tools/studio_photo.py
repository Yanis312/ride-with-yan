"""Pose un article détouré dans un studio fabriqué par programme :
mur sombre, halo de projecteur, sol, ombre portée. Le produit n'est pas modifié."""
import sys
import numpy as np
from PIL import Image, ImageFilter

S = 1200


def backdrop(warm=(245, 183, 0)):
    y, x = np.mgrid[0:S, 0:S].astype(np.float32) / S
    wall = np.array([34, 36, 44], np.float32)
    floor = np.array([20, 21, 26], np.float32)
    horizon = 0.76
    # Mur → sol, avec une transition douce (fond papier courbé).
    k = np.clip((y - horizon + 0.05) / 0.10, 0, 1)[..., None]
    img = wall * (1 - k) + floor * k
    # Halo du projecteur derrière le produit.
    d = np.sqrt(((x - 0.5) / 0.55) ** 2 + ((y - 0.42) / 0.5) ** 2)
    spot = np.clip(1 - d, 0, 1)[..., None] ** 1.8
    img += spot * np.array([70, 72, 82], np.float32)
    # Reflet chaud discret sur le sol.
    d2 = np.sqrt(((x - 0.5) / 0.5) ** 2 + ((y - 0.9) / 0.18) ** 2)
    img += np.clip(1 - d2, 0, 1)[..., None] ** 2 * np.array(warm, np.float32) * 0.10
    # Vignette et grain léger.
    v = np.clip(1 - 0.55 * ((x - 0.5) ** 2 + (y - 0.5) ** 2) * 2.2, 0, 1)[..., None]
    img *= v
    img += np.random.default_rng(3).normal(0, 2.2, (S, S, 1))
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert('RGBA')


def compose(cut_path, out_path, hang=True):
    cut = Image.open(cut_path).convert('RGBA')
    # Bords adoucis d'un pixel : pas de liseré dur autour du détourage.
    a = cut.getchannel('A').filter(ImageFilter.GaussianBlur(0.8))
    cut.putalpha(a)
    box = int(S * 0.74)
    cut.thumbnail((box, box), Image.LANCZOS)
    bg = backdrop()
    px = (S - cut.width) // 2
    py = int(S * 0.47 - cut.height / 2)
    # Ombre portée sur le mur, décalée et floue.
    sh = Image.new('RGBA', bg.size, (0, 0, 0, 0))
    shadow = Image.new('RGBA', cut.size, (0, 0, 0, 150))
    shadow.putalpha(cut.getchannel('A').point(lambda v: int(v * 0.6)))
    sh.alpha_composite(shadow, (px + 22, py + 30))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(26)))
    bg.alpha_composite(cut, (px, py))
    bg.convert('RGB').save(out_path, quality=90)


if __name__ == '__main__':
    compose(sys.argv[1], sys.argv[2])
