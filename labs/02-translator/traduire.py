"""Lab 2 — Translator : traduire un texte, détecter sa langue.

Ce que l'examen demande de savoir lire :
  1. TextTranslationClient(credential=AzureKeyCredential(CLÉ), region=RÉGION)
     ← adresse GLOBALE par défaut, donc la région est obligatoire
  2. translate(body=[textes], to_language=['en', 'es'])  ← plusieurs langues d'un coup
  3. sans from_language, le service DÉTECTE la langue (detected_language + score)
  4. transliterate : changer d'alphabet (ex. arabe → latin), pas de langue

Usage :
  python 02-translator/traduire.py "Une paire et un maillot pour 120 $."
"""
import sys
from pathlib import Path

from azure.ai.translation.text import TextTranslationClient
from azure.core.credentials import AzureKeyCredential

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402


def client() -> TextTranslationClient:
    return TextTranslationClient(
        credential=AzureKeyCredential(cle('TRANSLATOR_KEY')),
        region=cle('AZURE_REGION'),
    )


def traduire(texte: str, langues: list[str]) -> None:
    reponse = client().translate(body=[texte], to_language=langues)

    for element in reponse:
        detectee = element.detected_language
        if detectee:
            print(f'Langue détectée : {detectee.language} (confiance {detectee.score:.0%})')
        for traduction in element.translations:
            # SDK 2.0 : « language » (l'ancien SDK et la doc REST disent « to »)
            print(f'  {traduction.language} : {traduction.text}')


def translitterer(texte: str) -> None:
    resultat = client().transliterate(
        body=[texte], language='ar', from_script='Arab', to_script='Latn')
    print(f'Translittération : {texte} → {resultat[0].text}')


if __name__ == '__main__':
    traduire(sys.argv[1] if len(sys.argv) > 1 else
             'Une paire et un maillot pour 120 $, livrés en 30 jours.', ['en', 'es', 'ar'])
    translitterer('مرحبا')
