"""Lab 4 — Vision : lire le texte d'une image (OCR) et la décrire.

Ce que l'examen demande de savoir lire :
  1. ImageAnalysisClient(endpoint=ADRESSE, credential=AzureKeyCredential(CLÉ))
  2. analyze_from_url(url, visual_features=[...])  ou  analyze(image_data=octets, ...)
  3. les VisualFeatures : READ (OCR), CAPTION (une phrase), DENSE_CAPTIONS,
     TAGS (mots-clés), OBJECTS (objets + cadres), PEOPLE, SMART_CROPS
  4. lire l'OCR : result.read.blocks → lines → words (avec confidence)
  5. CAPTION n'existe que dans certaines régions : pas Canada Centre

Usage :
  python 04-vision/lire.py                       → image d'exemple de Microsoft
  python 04-vision/lire.py carte-commerce.jpg    → ta photo
"""
import sys
from pathlib import Path

from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

EXEMPLE = 'https://aka.ms/azsdk/image-analysis/sample.jpg'
FONCTIONS = [VisualFeatures.READ, VisualFeatures.TAGS, VisualFeatures.OBJECTS]


def analyser(image: str) -> None:
    client = ImageAnalysisClient(
        endpoint=cle('VISION_ENDPOINT'),
        credential=AzureKeyCredential(cle('VISION_KEY')),
    )
    if image.startswith('http'):
        resultat = client.analyze_from_url(image_url=image, visual_features=FONCTIONS)
    else:
        resultat = client.analyze(image_data=Path(image).read_bytes(), visual_features=FONCTIONS)

    print('— Texte lu (OCR)')
    if resultat.read:
        for bloc in resultat.read.blocks:
            for ligne in bloc.lines:
                print('  ', ligne.text)

    print('— Mots-clés')
    if resultat.tags:
        print('  ', ', '.join(f'{t.name} {t.confidence:.0%}' for t in resultat.tags.list[:8]))

    print('— Objets')
    if resultat.objects:
        for objet in resultat.objects.list:
            boite = objet.bounding_box
            print(f'   {objet.tags[0].name} à x={boite.x}, y={boite.y} ({boite.width}×{boite.height})')


if __name__ == '__main__':
    analyser(sys.argv[1] if len(sys.argv) > 1 else EXEMPLE)
