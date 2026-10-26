"""Lab 1 — Speech : synthèse vocale (texte → voix) et reconnaissance (voix → texte).

Ce que l'examen demande de savoir lire :
  1. SpeechConfig(subscription=CLÉ, region=RÉGION)   ← région, pas l'adresse
  2. choisir la voix : speech_synthesis_voice_name
  3. AudioConfig : haut-parleur, fichier ou micro
  4. SpeechSynthesizer / SpeechRecognizer
  5. ..._async().get() puis vérifier result.reason (ResultReason)

Usage :
  python 01-speech/parler.py "Bonjour, je suis Yan."        → reponse.wav
  python 01-speech/parler.py --ecouter question.wav          → texte reconnu
"""
import sys
from pathlib import Path

import azure.cognitiveservices.speech as speechsdk

sys.path.insert(0, str(Path(__file__).parent.parent))
from cles import cle  # noqa: E402

# Voix neuronales du Canada : français du Québec et anglais canadien.
VOIX = {'fr': 'fr-CA-SylvieNeural', 'en': 'en-CA-ClaraNeural'}


def config() -> speechsdk.SpeechConfig:
    return speechsdk.SpeechConfig(subscription=cle('SPEECH_KEY'), region=cle('AZURE_REGION'))


def dire(texte: str, langue: str = 'fr', fichier: str = 'reponse.wav') -> None:
    speech_config = config()
    speech_config.speech_synthesis_voice_name = VOIX[langue]
    audio = speechsdk.audio.AudioOutputConfig(filename=fichier)
    synthese = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=audio)

    resultat = synthese.speak_text_async(texte).get()

    if resultat.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
        print(f'Voix enregistrée dans {fichier} ({len(resultat.audio_data)} octets).')
    elif resultat.reason == speechsdk.ResultReason.Canceled:
        details = resultat.cancellation_details
        print('Annulé :', details.reason, details.error_details)


def ecouter(fichier: str, langue: str = 'fr-CA') -> None:
    speech_config = config()
    speech_config.speech_recognition_language = langue
    audio = speechsdk.audio.AudioConfig(filename=fichier)  # ou use_default_microphone=True
    reconnaissance = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio)

    resultat = reconnaissance.recognize_once_async().get()

    if resultat.reason == speechsdk.ResultReason.RecognizedSpeech:
        print('Reconnu :', resultat.text)
    elif resultat.reason == speechsdk.ResultReason.NoMatch:
        print('Rien de reconnu.')
    else:
        print('Annulé :', resultat.cancellation_details.error_details)


if __name__ == '__main__':
    if len(sys.argv) > 2 and sys.argv[1] == '--ecouter':
        ecouter(sys.argv[2])
    else:
        dire(sys.argv[1] if len(sys.argv) > 1 else 'Bonjour, je suis Yan, votre assistant de bord.')
