import 'package:flutter/widgets.dart';

import 'bilingual.dart';

/// Morceau du coin musique : vidéo officielle YouTube (lecteur intégré,
/// gratuit et autorisé). Chaque identifiant a été vérifié avec l'oEmbed de
/// YouTube, qui confirme que l'intégration est permise.
@immutable
class Track {
  const Track(this.videoId, this.title, this.artist, this.mood);

  final String videoId;
  final String title;
  final String artist;
  final Bi mood;

  String get thumbnail => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
}

/// La chanson de Yanis, mise en avant partout.
const yanFavorite = Track(
  'tAGnKpE4NCI',
  'Nothing Else Matters',
  'Metallica',
  Bi('Légende du rock', 'Rock legend'),
);

const _rock = Bi('Rock', 'Rock');
const _pop = Bi('Pop', 'Pop');
const _groove = Bi('Groove', 'Groove');
const _chill = Bi('Détente', 'Chill');

const playlist = [
  yanFavorite,
  Track('fJ9rUzIMcZQ', 'Bohemian Rhapsody', 'Queen', _rock),
  Track('09839DpTctU', 'Hotel California (Live 1977)', 'Eagles', _rock),
  Track('1w7OgIMMRc4', 'Sweet Child O’ Mine', 'Guns N’ Roses', _rock),
  Track('pAgnJDJN4VA', 'Back In Black', 'AC/DC', _rock),
  Track('hTWKbfoikeg', 'Smells Like Teen Spirit', 'Nirvana', _rock),
  Track('kXYiU_JCYtU', 'Numb', 'Linkin Park', _rock),
  Track('btPJPFnesV4', 'Eye Of The Tiger', 'Survivor', _rock),
  Track('4NRXx6U8ABQ', 'Blinding Lights', 'The Weeknd', _pop),
  Track('dvgZkm1xWPE', 'Viva La Vida', 'Coldplay', _pop),
  Track('7wtfhZwyrcc', 'Believer', 'Imagine Dragons', _pop),
  Track('YQHsXMglC9A', 'Hello', 'Adele', _pop),
  Track('2Vv-BfVoq4g', 'Perfect', 'Ed Sheeran', _pop),
  Track('lp-EO5I60KA', 'Thinking Out Loud', 'Ed Sheeran', _pop),
  Track('5NV6Rdv1a3I', 'Get Lucky', 'Daft Punk ft. Pharrell Williams', _groove),
  Track('VHoT4N43jK8', 'Alors on danse', 'Stromae', _groove),
  Track('I_izvAbhExY', 'Stayin’ Alive', 'Bee Gees', _groove),
  Track('jfKfPfyJRdk', 'lofi hip hop radio', 'Lofi Girl', _chill),
];
