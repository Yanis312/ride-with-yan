"""Lab 3 — Language : analyser les avis des passagers.

Ce que l'examen demande de savoir lire :
  1. TextAnalyticsClient(endpoint=ADRESSE, credential=AzureKeyCredential(CLÉ))
     ← ici l'ADRESSE de la ressource, pas la région
  2. on envoie une LISTE de documents, on reçoit un résultat par document
  3. toujours vérifier doc.is_error avant de lire le résultat
  4. les fonctions à reconnaître :
       detect_language          → langue
       analyze_sentiment        → positive / neutral / negative / mixed (+ scores)
       extract_key_phrases      → phrases clés
       recognize_entities       → personnes, lieux, dates… (NER)
       recognize_pii_entities   → données personnelles, et texte masqué (redacted_text)

Usage :
  python 03-language/avis.py
"""
import sys
from pathlib import Path

from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

AVIS = [
    'Super course jusqu\'à Gatineau, Yan est très gentil et la tablette est géniale !',
    'Le trajet était long et la musique trop forte.',
    'Appelez-moi au 613-555-0199, je veux commander des chaussures. Marie Tremblay',
]


def client() -> TextAnalyticsClient:
    return TextAnalyticsClient(
        endpoint=cle('LANGUAGE_ENDPOINT'),
        credential=AzureKeyCredential(cle('LANGUAGE_KEY')),
    )


def analyser() -> None:
    langue = client()

    print('— Langue')
    for doc in langue.detect_language(AVIS):
        if not doc.is_error:
            print(f'  {doc.primary_language.name} ({doc.primary_language.iso6391_name})')

    print('— Sentiment')
    for texte, doc in zip(AVIS, langue.analyze_sentiment(AVIS, language='fr')):
        if not doc.is_error:
            s = doc.confidence_scores
            print(f'  {doc.sentiment:8} (+{s.positive:.2f} / ={s.neutral:.2f} / -{s.negative:.2f})'
                  f'  {texte[:45]}…')

    print('— Phrases clés')
    for doc in langue.extract_key_phrases(AVIS, language='fr'):
        if not doc.is_error:
            print('  ', ', '.join(doc.key_phrases))

    print('— Entités nommées')
    for doc in langue.recognize_entities(AVIS, language='fr'):
        if not doc.is_error:
            print('  ', ', '.join(f'{e.text} [{e.category}]' for e in doc.entities))

    print('— Données personnelles masquées')
    for doc in langue.recognize_pii_entities(AVIS, language='fr'):
        if not doc.is_error:
            print('  ', doc.redacted_text)


if __name__ == '__main__':
    analyser()
