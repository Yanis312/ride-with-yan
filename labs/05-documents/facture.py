"""Lab 5 — Document Intelligence : lire une facture avec un modèle prêt à l'emploi.

Ce que l'examen demande de savoir lire :
  1. DocumentIntelligenceClient(endpoint=ADRESSE, credential=AzureKeyCredential(CLÉ))
  2. begin_analyze_document(MODÈLE, ...) → une opération LONGUE (poller),
     puis .result()
  3. les modèles prêts : prebuilt-read (texte), prebuilt-layout (tableaux),
     prebuilt-invoice, prebuilt-receipt, prebuilt-idDocument, prebuilt-businessCard…
     et les modèles PERSONNALISÉS (entraînés sur tes propres documents)
  4. result.documents[0].fields["InvoiceTotal"] : valeur + confidence

Différence avec Vision (lab 4) : Vision lit le texte ; Document Intelligence
comprend la STRUCTURE (quel nombre est le total, quel nom est le fournisseur).

Usage :
  python 05-documents/facture.py                 → facture d'exemple de Microsoft
  python 05-documents/facture.py ma-facture.pdf
"""
import sys
from pathlib import Path

from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.ai.documentintelligence.models import AnalyzeDocumentRequest
from azure.core.credentials import AzureKeyCredential

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

EXEMPLE = ('https://raw.githubusercontent.com/Azure-Samples/cognitive-services-REST-api-samples/'
           'master/curl/form-recognizer/sample-invoice.pdf')
CHAMPS = ['VendorName', 'CustomerName', 'InvoiceId', 'InvoiceDate', 'DueDate', 'InvoiceTotal']


def lire(document: str) -> None:
    client = DocumentIntelligenceClient(
        endpoint=cle('DOCUMENTS_ENDPOINT'),
        credential=AzureKeyCredential(cle('DOCUMENTS_KEY')),
    )
    if document.startswith('http'):
        source = AnalyzeDocumentRequest(url_source=document)
    else:
        source = AnalyzeDocumentRequest(bytes_source=Path(document).read_bytes())

    operation = client.begin_analyze_document('prebuilt-invoice', source)
    resultat = operation.result()  # attend la fin de l'analyse

    for facture in resultat.documents:
        print(f'Type : {facture.doc_type} (confiance {facture.confidence:.0%})')
        for nom in CHAMPS:
            champ = facture.fields.get(nom)
            if champ:
                print(f'  {nom:13} {champ.content!s:35} {champ.confidence:.0%}')

        lignes = facture.fields.get('Items')
        if lignes:
            print('  Articles :')
            for article in lignes.value_array:
                description = article.value_object.get('Description')
                montant = article.value_object.get('Amount')
                print(f'    - {description.content if description else "?"}'
                      f'  {montant.content if montant else ""}')


if __name__ == '__main__':
    lire(sys.argv[1] if len(sys.argv) > 1 else EXEMPLE)
