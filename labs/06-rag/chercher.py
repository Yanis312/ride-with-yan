"""Lab 6 — AI Search + RAG : Yan répond à partir d'une base de connaissances.

RAG = Retrieval-Augmented Generation :
  1. RECHERCHER les passages utiles dans un index (AI Search)
  2. les DONNER au modèle avec la question
  3. le modèle GÉNÈRE une réponse appuyée sur ces passages (moins d'inventions)

Ce que l'examen demande de savoir lire :
  - SearchIndexClient : créer / supprimer un INDEX (le schéma : champs, clé,
    searchable, filterable, analyseur de langue)
  - SearchClient : upload_documents (indexer) puis search (interroger)
  - types de recherche : mots-clés (BM25), vectorielle (embeddings),
    hybride (les deux), sémantique (re-classement par un modèle)
  - un indexeur peut aussi remplir l'index tout seul depuis Blob Storage, SQL…

Usage :
  python 06-rag/chercher.py                      → crée l'index et pose 3 questions
  python 06-rag/chercher.py "Livrez-vous à Gatineau ?"
"""
import sys
from pathlib import Path

from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchableField,
    SearchIndex,
    SimpleField,
)
from openai import AzureOpenAI

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

INDEX = 'yan-connaissances'
FICHES = [
    {'id': '1', 'titre': 'Prix', 'contenu': 'Toutes les chaussures coûtent 80 $. Les maillots coûtent 50 $.'},
    {'id': '2', 'titre': 'Combo', 'contenu': 'Une paire de chaussures et un maillot ensemble coûtent 120 $ au lieu de 130 $.'},
    {'id': '3', 'titre': 'Livraison', 'contenu': 'Tout est sur commande. La livraison prend environ 30 jours partout à Ottawa et Gatineau.'},
    {'id': '4', 'titre': 'Paiement', 'contenu': 'On peut payer un acompte maintenant par virement Interac, et le reste à la livraison.'},
    {'id': '5', 'titre': 'Urgence', 'contenu': 'En cas d\'urgence pendant la course, appelez le 911.'},
]


def creer_index() -> None:
    index = SearchIndex(name=INDEX, fields=[
        SimpleField(name='id', type='Edm.String', key=True),
        SearchableField(name='titre', type='Edm.String', analyzer_name='fr.microsoft'),
        SearchableField(name='contenu', type='Edm.String', analyzer_name='fr.microsoft'),
    ])
    admin = SearchIndexClient(cle('SEARCH_ENDPOINT'), AzureKeyCredential(cle('SEARCH_KEY')))
    admin.create_or_update_index(index)
    recherche().upload_documents(documents=FICHES)
    print(f'Index « {INDEX} » prêt : {len(FICHES)} fiches.')


def recherche() -> SearchClient:
    return SearchClient(cle('SEARCH_ENDPOINT'), INDEX, AzureKeyCredential(cle('SEARCH_KEY')))


def repondre(question: str) -> None:
    # 1. Retrieval : les 2 fiches les plus pertinentes
    trouves = list(recherche().search(search_text=question, top=2))
    sources = '\n'.join(f"[{d['titre']}] {d['contenu']}" for d in trouves)
    print(f'\nQ : {question}')
    print('   sources :', ', '.join(f"{d['titre']} ({d['@search.score']:.2f})" for d in trouves) or 'aucune')

    # 2 et 3. Augmented Generation : le modèle ne répond QU'AVEC ces sources
    modele = AzureOpenAI(azure_endpoint=cle('FOUNDRY_ENDPOINT'), api_key=cle('FOUNDRY_KEY'),
                         api_version='2024-10-21')
    reponse = modele.chat.completions.create(
        model=cle('FOUNDRY_DEPLOYMENT'),  # le nom du DÉPLOIEMENT, pas du modèle
        max_tokens=120,
        messages=[
            {'role': 'system', 'content': 'Tu es Yan. Réponds en une phrase, uniquement avec '
             'les sources ci-dessous. Si elles ne suffisent pas, dis que tu ne sais pas.\n' + sources},
            {'role': 'user', 'content': question},
        ],
    )
    print('R :', reponse.choices[0].message.content)


if __name__ == '__main__':
    creer_index()
    for q in sys.argv[1:] or ['Combien coûte le combo ?',
                              'Livrez-vous à Gatineau et en combien de temps ?',
                              'Avez-vous des casquettes ?']:
        repondre(q)
