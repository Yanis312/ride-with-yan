"""Lit les clés et adresses des services depuis labs/.env.

Le fichier .env est écrit par : python cles.py --depuis-terraform
(il lit les sorties de Terraform dans infra/azure, sans rien afficher).
"""
import json
import os
import subprocess
import sys
from pathlib import Path

from dotenv import load_dotenv

ICI = Path(__file__).parent
load_dotenv(ICI / '.env')


def cle(nom: str) -> str:
    valeur = os.getenv(nom)
    if not valeur:
        sys.exit(f'{nom} manquant : lance « python cles.py --depuis-terraform ».')
    return valeur


def depuis_terraform() -> None:
    terraform = Path(os.environ['LOCALAPPDATA']) / 'Microsoft/WinGet/Links/terraform.exe'
    dossier = ICI.parent / 'infra' / 'azure'

    def sortie(nom: str):
        texte = subprocess.run(
            [str(terraform), 'output', '-json', nom],
            cwd=dossier, capture_output=True, text=True, check=True,
        ).stdout
        return json.loads(texte)

    adresses, cles_ = sortie('lab_endpoints'), sortie('lab_keys')
    lignes = [
        # Speech et Translator demandent la RÉGION en plus de la clé.
        'AZURE_REGION=canadacentral',
        f"SEARCH_ENDPOINT={sortie('search_endpoint')}",
        f"SEARCH_KEY={sortie('search_admin_key')}",
        # Le modèle de Yan (Foundry), pour la partie « génération » du RAG.
        f"FOUNDRY_ENDPOINT={sortie('endpoint')}",
        f"FOUNDRY_KEY={sortie('api_key')}",
        f"FOUNDRY_DEPLOYMENT={sortie('deployment')}",
    ]
    for service in adresses:
        nom = service.upper()
        lignes.append(f'{nom}_ENDPOINT={adresses[service]}')
        lignes.append(f'{nom}_KEY={cles_[service]}')
    (ICI / '.env').write_text('\n'.join(lignes) + '\n', encoding='utf-8')
    print(f'.env écrit : {len(adresses)} services + recherche (clés non affichées).')


if __name__ == '__main__' and '--depuis-terraform' in sys.argv:
    depuis_terraform()
