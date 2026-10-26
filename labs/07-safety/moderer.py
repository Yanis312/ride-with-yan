"""Lab 7 — Content Safety : modérer un texte avant de le publier.

Ce que l'examen demande de savoir lire :
  1. ContentSafetyClient(endpoint=ADRESSE, credential=AzureKeyCredential(CLÉ))
  2. analyze_text(AnalyzeTextOptions(text=...))  /  analyze_image(AnalyzeImageOptions(...))
  3. 4 catégories : Hate, SelfHarm, Sexual, Violence
  4. une SÉVÉRITÉ par catégorie : 0 (sûr), 2 (bas), 4 (moyen), 6 (élevé)
     → c'est TON code qui choisit le seuil de refus
  5. autres outils du service : blocklists (mots interdits à toi),
     Prompt Shields (tentatives de détournement d'un modèle),
     groundedness (la réponse s'appuie-t-elle sur les sources ?)

Usage :
  python 07-safety/moderer.py "Texte d'un avis à vérifier"
"""
import sys
from pathlib import Path

from azure.ai.contentsafety import ContentSafetyClient
from azure.ai.contentsafety.models import AnalyzeTextOptions
from azure.core.credentials import AzureKeyCredential

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

SEUIL = 4  # on refuse à partir de « moyen »
EXEMPLES = [
    'Super course, merci Yan !',
    'Ce chauffeur est nul, je vais le frapper la prochaine fois.',  # 0 : trop vague
    'Je vais tuer ce chauffeur avec un couteau.',                     # Violence 4
]


def moderer(texte: str) -> None:
    client = ContentSafetyClient(
        endpoint=cle('SAFETY_ENDPOINT'),
        credential=AzureKeyCredential(cle('SAFETY_KEY')),
    )
    resultat = client.analyze_text(AnalyzeTextOptions(text=texte))

    severites = {c.category: c.severity for c in resultat.categories_analysis}
    decision = 'REFUSÉ' if max(severites.values()) >= SEUIL else 'accepté'
    print(f'{decision:8} {severites}  « {texte} »')


if __name__ == '__main__':
    for texte in sys.argv[1:] or EXEMPLES:
        moderer(texte)
